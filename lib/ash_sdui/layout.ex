defmodule AshSDUI.Layout do
  @moduledoc """
  Unified API for named UI layouts.

  Layouts can be registered in code or stored as `UINode` records. Callers
  should use `fetch/2` when they do not need to care where a layout lives.

  `AshSDUI.Layout.Node` represents a layout definition tree: component name,
  subject binding, static props, and child layout nodes. Rendering happens one
  step later through `AshSDUI.Renderer`, which converts the definition tree into
  `%AshSDUI.Renderer.TreeNode{}` structs for LiveView rendering.

  Source precedence:

  - `source: :registered` only reads code-registered layouts.
  - `source: :stored` only reads persisted layouts.
  - `source: :any` checks registered layouts first, then stored layouts.

  The built-in `AshSDUI.UINode` is suitable for tests, demos, and prototypes.
  Production apps can pass `node_resource:` to use a compatible Ash resource.
  A compatible node resource is expected to expose:

  - layout fields matching `component_name`, `static_props`, `subject_resource`,
    `subject_id`, `region`, `order`, `status`, `name`, and `parent_id`
  - `:create`, `:read`, `:destroy`, and `:publish` actions
  - an `:update` action when callers intend to update stored nodes directly
  """

  require Ash.Query

  @layout_key {__MODULE__, :layouts}

  defmodule Node do
    @moduledoc """
    Definition-time layout node used by `AshSDUI.Layout` and
    `AshSDUI.Layout.Builder`.

    This struct is intentionally distinct from `%AshSDUI.Renderer.TreeNode{}`:
    `Node` is authored or persisted, while `TreeNode` is the render-ready shape
    consumed by `AshSDUI.Components.SDUIRoot`.
    """
    defstruct [
      :id,
      :component,
      :region,
      :order,
      :subject_resource,
      :subject_id,
      :static_props,
      :children
    ]

    @type t :: %__MODULE__{
            id: term,
            component: String.t(),
            region: atom,
            order: integer,
            subject_resource: String.t() | nil,
            subject_id: String.t() | nil,
            static_props: map | nil,
            children: [t]
          }
  end

  defmodule LayoutDef do
    @moduledoc false
    defstruct [:name, :root]

    @type t :: %__MODULE__{
            name: String.t(),
            root: AshSDUI.Layout.Node.t()
          }
  end

  @type status :: :draft | :published | :archived
  @type source :: :registered | :stored | :any
  @typedoc """
  Persisted-layout storage resource. Defaults to `AshSDUI.UINode`.

  Compatible resources should expose the fields and actions documented in the
  module docs for `AshSDUI.Layout`.
  """
  @type node_resource :: module

  @type layout_opt ::
          {:source, source}
          | {:status, status | :any}
          | {:node_resource, node_resource}
          | {:resource, module}
          | {:replace?, boolean}

  def register(name, %Node{} = root) when is_binary(name) do
    register(name, %LayoutDef{name: name, root: root})
  end

  def register(name, layout_def) do
    current =
      case :persistent_term.get(@layout_key, nil) do
        nil -> %{}
        map -> map
      end

    :persistent_term.put(@layout_key, Map.put(current, name, layout_def))
  end

  @doc """
  Returns a named layout from the requested source.

  By default registered layouts are checked first, then stored layouts.
  """
  @spec fetch(String.t(), [layout_opt]) :: {:ok, LayoutDef.t()} | {:error, :not_found}
  def fetch(name, opts \\ []) when is_binary(name) do
    case Keyword.get(opts, :source, :any) do
      :registered -> get(name)
      :stored -> fetch_stored(name, opts)
      :any -> fetch_any(name, opts)
    end
  end

  def get(name) do
    map =
      case :persistent_term.get(@layout_key, nil) do
        nil -> %{}
        m -> m
      end

    case Map.get(map, name) do
      nil -> {:error, :not_found}
      layout -> {:ok, layout}
    end
  end

  def all do
    case :persistent_term.get(@layout_key, nil) do
      nil -> []
      map -> Map.values(map)
    end
  end

  @doc """
  Stores a layout tree as `UINode` records.
  """
  @spec save(String.t(), Node.t(), [layout_opt]) :: {:ok, [struct]} | {:error, term}
  def save(name, %Node{} = root, opts \\ []) when is_binary(name) do
    resource = node_resource(opts)
    status = Keyword.get(opts, :status, :draft)
    replace? = Keyword.get(opts, :replace?, true)

    with :ok <- maybe_delete_existing(resource, name, replace?),
         {:ok, records} <- create_nodes(resource, root, name, status, nil) do
      AshSDUI.Cache.evict(name)
      {:ok, records}
    end
  end

  @doc """
  Returns stored layout nodes for a layout name.
  """
  @spec load_nodes(String.t(), [layout_opt]) :: {:ok, [struct]} | {:error, term}
  def load_nodes(name, opts \\ []) when is_binary(name) do
    resource = node_resource(opts)
    status = Keyword.get(opts, :status, :published)

    nodes =
      resource
      |> query_by_name_and_status(name, status)
      |> Ash.read!()

    if nodes == [] do
      {:error, :not_found}
    else
      {:ok, nodes}
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  Marks all stored nodes for a layout name as published.
  """
  @spec publish(String.t(), [layout_opt]) :: {:ok, [struct]} | {:error, term}
  def publish(name, opts \\ []) when is_binary(name) do
    with {:ok, nodes} <- load_nodes(name, Keyword.put(opts, :status, :any)) do
      nodes
      |> Enum.map(fn node ->
        node
        |> Ash.Changeset.for_update(:publish, %{})
        |> Ash.update()
      end)
      |> collect_results()
      |> case do
        {:ok, records} ->
          AshSDUI.Cache.evict(name)
          {:ok, records}

        error ->
          error
      end
    end
  end

  defp fetch_any(name, opts) do
    case get(name) do
      {:ok, layout} -> {:ok, layout}
      {:error, :not_found} -> fetch_stored(name, opts)
    end
  end

  defp fetch_stored(name, opts) do
    with {:ok, nodes} <- load_nodes(name, opts),
         {:ok, root} <- root_from_records(nodes) do
      {:ok, %LayoutDef{name: name, root: root}}
    end
  end

  defp root_from_records(records) do
    case Enum.find(records, &is_nil(Map.get(&1, :parent_id))) do
      nil -> {:error, :no_root_node}
      root -> {:ok, node_from_record(root, records)}
    end
  end

  defp node_from_record(record, records) do
    children =
      records
      |> Enum.filter(&(Map.get(&1, :parent_id) == record.id))
      |> Enum.sort_by(& &1.order)
      |> Enum.map(&node_from_record(&1, records))

    %Node{
      id: record.id,
      component: record.component_name,
      region: record.region,
      order: record.order,
      subject_resource: record.subject_resource,
      subject_id: record.subject_id,
      static_props: record.static_props || %{},
      children: children
    }
  end

  defp maybe_delete_existing(_resource, _name, false), do: :ok

  defp maybe_delete_existing(resource, name, true) do
    results =
      resource
      |> query_by_name_and_status(name, :any)
      |> Ash.read!()
      |> Enum.map(&Ash.destroy/1)

    if Enum.all?(results, &match?(:ok, &1)) do
      :ok
    else
      {:error, results}
    end
  rescue
    error -> {:error, error}
  end

  defp create_nodes(resource, %Node{} = node, name, status, parent_id) do
    params = %{
      name: name,
      component_name: node.component,
      static_props: node.static_props || %{},
      subject_resource: node.subject_resource,
      subject_id: node.subject_id,
      region: node.region,
      order: node.order,
      status: status,
      parent_id: parent_id
    }

    with {:ok, record} <- resource |> Ash.Changeset.for_create(:create, params) |> Ash.create(),
         {:ok, children} <-
           create_children(resource, node.children || [], name, status, record.id) do
      {:ok, [record | children]}
    end
  end

  defp create_children(_resource, [], _name, _status, _parent_id), do: {:ok, []}

  defp create_children(resource, children, name, status, parent_id) do
    children
    |> Enum.sort_by(& &1.order)
    |> Enum.map(&create_nodes(resource, &1, name, status, parent_id))
    |> collect_results()
  end

  defp collect_results(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {:ok, records}, {:ok, acc} when is_list(records) ->
        {:cont, {:ok, acc ++ records}}

      {:ok, record}, {:ok, acc} ->
        {:cont, {:ok, [record | acc]}}

      {:error, reason}, _acc ->
        {:halt, {:error, reason}}
    end)
  end

  defp query_by_name_and_status(resource, name, :any) do
    layout_name = name
    Ash.Query.filter(resource, name == ^layout_name)
  end

  defp query_by_name_and_status(resource, name, status) do
    layout_name = name
    layout_status = status

    Ash.Query.filter(resource, name == ^layout_name and status == ^layout_status)
  end

  defp node_resource(opts) do
    Keyword.get(opts, :node_resource) || Keyword.get(opts, :resource) || AshSDUI.UINode
  end
end
