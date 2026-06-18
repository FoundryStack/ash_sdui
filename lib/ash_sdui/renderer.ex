defmodule AshSDUI.Renderer do
  @moduledoc """
  Converts a UI graph (from DB records or code-based layouts) into a nested
  tree of `%AshSDUI.Renderer.TreeNode{}` structs ready for rendering.

  The renderer is the boundary between authored layout definitions and rendered
  SDUI trees:

  - `AshSDUI.Layout.Node` is the definition/persistence shape
  - `AshSDUI.Renderer.TreeNode` is the render-ready shape

  LiveViews and `AshSDUI.Components.SDUIRoot` should work with `TreeNode`
  values, while builders, registries, and persistence APIs should work with
  `Layout.Node`.
  """

  defmodule TreeNode do
    @moduledoc """
    Render-ready node produced by `AshSDUI.Renderer`.

    This shape mirrors `AshSDUI.Layout.Node`, but normalizes component naming to
    `component_name` and is the tree consumed by `AshSDUI.Components.SDUIRoot`.
    """
    defstruct [
      :id,
      :component_name,
      :static_props,
      :subject_resource,
      :subject_id,
      :region,
      :order,
      :refresh,
      :binding,
      :variant,
      :state_key,
      :children
    ]
  end

  @doc """
  Converts either a list of UINode records or a layout name string into a
  nested TreeNode struct suitable for rendering.

  Use this when you need a renderable tree. If you need the definition tree for
  registration or persistence work, use `AshSDUI.Layout.fetch/2` instead.
  """
  def to_tree(layout_name, opts \\ [])

  def to_tree(layout_name, opts) when is_binary(layout_name) do
    case cached_tree(layout_name, opts) do
      {:ok, tree} ->
        {:ok, tree}

      :skip ->
        build_tree(layout_name, opts)

      {:error, :not_found} ->
        result = build_tree(layout_name, opts)

        case result do
          {:ok, tree} ->
            maybe_cache_tree(layout_name, opts, tree)
            {:ok, tree}

          err ->
            err
        end
    end
  end

  def to_tree(records, _opts) when is_list(records) do
    # Build tree from a flat list of UINode records
    root =
      Enum.find(records, fn r ->
        is_nil(Map.get(r, :parent_id))
      end)

    if root do
      {:ok, build_from_records(root, records)}
    else
      {:error, :no_root_node}
    end
  end

  defp build_tree(layout_name, opts) do
    case AshSDUI.Layout.fetch(layout_name, opts) do
      {:ok, layout_def} ->
        {:ok, layout_node_to_tree(layout_def.root)}

      {:error, :not_found} ->
        {:error, {:not_found, layout_name}}
    end
  end

  defp build_from_records(node, all_records) do
    {static_props, runtime_meta} = split_runtime_meta(node.static_props || %{})

    children =
      all_records
      |> Enum.filter(&(Map.get(&1, :parent_id) == node.id))
      |> Enum.sort_by(& &1.order)
      |> Enum.map(&build_from_records(&1, all_records))

    %TreeNode{
      id: node.id,
      component_name: node.component_name,
      static_props: static_props,
      subject_resource: node.subject_resource,
      subject_id: node.subject_id,
      region: node.region,
      order: node.order,
      refresh: Map.get(runtime_meta, :refresh),
      binding: Map.get(runtime_meta, :binding),
      variant: Map.get(runtime_meta, :variant),
      state_key: Map.get(runtime_meta, :state_key),
      children: children
    }
  end

  defp layout_node_to_tree(nil), do: nil

  defp layout_node_to_tree(%AshSDUI.Layout.Node{} = node) do
    children =
      (node.children || [])
      |> Enum.sort_by(& &1.order)
      |> Enum.map(&layout_node_to_tree/1)

    %TreeNode{
      id: node.id,
      component_name: node.component,
      static_props: node.static_props || %{},
      subject_resource: node.subject_resource,
      subject_id: node.subject_id,
      region: node.region,
      order: node.order,
      refresh: node.refresh,
      binding: node.binding,
      variant: node.variant,
      state_key: node.state_key,
      children: children
    }
  end

  defp cached_tree(layout_name, opts) do
    if cacheable?(opts) do
      AshSDUI.Cache.get(layout_name)
    else
      :skip
    end
  end

  defp maybe_cache_tree(layout_name, opts, tree) do
    if cacheable?(opts) do
      AshSDUI.Cache.put(layout_name, tree)
    end
  end

  defp cacheable?(opts) do
    Keyword.get(opts, :source, :any) == :any and
      Keyword.get(opts, :status, :published) == :published and
      Keyword.get(opts, :node_resource, AshSDUI.UINode) == AshSDUI.UINode and
      not Keyword.has_key?(opts, :resource)
  end

  @runtime_meta_key "__ash_sdui__"

  defp split_runtime_meta(static_props) do
    runtime_meta =
      Map.get(static_props, @runtime_meta_key) ||
        Map.get(static_props, String.to_atom(@runtime_meta_key)) ||
        %{}

    {
      Map.drop(static_props, [@runtime_meta_key, String.to_atom(@runtime_meta_key)]),
      normalize_runtime_meta(runtime_meta)
    }
  end

  defp normalize_runtime_meta(runtime_meta) when is_map(runtime_meta) do
    %{
      refresh: read_meta(runtime_meta, :refresh),
      binding: read_meta(runtime_meta, :binding),
      variant: read_meta(runtime_meta, :variant),
      state_key: read_meta(runtime_meta, :state_key)
    }
  end

  defp normalize_runtime_meta(_runtime_meta), do: %{}

  defp read_meta(meta, key) do
    Map.get(meta, key) || Map.get(meta, Atom.to_string(key))
  end
end
