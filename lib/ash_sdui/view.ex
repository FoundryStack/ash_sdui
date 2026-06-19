defmodule AshSDUI.View do
  @moduledoc """
  Generic intermediate representation for an Ash-backed UI view.

  A view resolves resource metadata, query state, bindings, and user intents into
  a compact runtime model.
  """

  alias AshSDUI.Binding
  alias AshSDUI.Context
  alias AshSDUI.Intent
  alias AshSDUI.Layout.Builder
  alias AshSDUI.LayoutRecipe.Registry
  alias AshSDUI.Query
  alias AshSDUI.Runtime.Normalize
  alias AshSDUI.Runtime.RecipeOverrides
  alias AshSDUI.Resource.Info

  defmodule Field do
    @moduledoc false
    defstruct [
      :name,
      :label,
      :widget,
      :type,
      :required,
      :input_source,
      :relationship,
      :relationship_type,
      :option_label,
      :option_value,
      :prompt,
      :read_action,
      :options,
      :multiple?,
      :order,
      :hidden,
      :field_component,
      :filter?,
      :sortable?,
      :format,
      :empty_state,
      :badge?,
      :binding,
      :source
    ]

    @type t :: %__MODULE__{
            name: atom,
            label: String.t(),
            widget: atom | nil,
            type: term,
            required: boolean,
            input_source: :attribute | :argument | nil,
            relationship: atom | nil,
            relationship_type: atom | nil,
            option_label: atom | nil,
            option_value: atom | nil,
            prompt: String.t() | nil,
            read_action: atom | nil,
            options: [{String.t(), term}],
            multiple?: boolean,
            order: non_neg_integer,
            hidden: boolean,
            field_component: module | nil,
            filter?: boolean,
            sortable?: boolean,
            format: atom | nil,
            empty_state: String.t() | nil,
            badge?: boolean,
            binding: atom | nil,
            source: term
          }
  end

  defmodule State do
    @moduledoc false
    defstruct [
      :query,
      params: %{},
      selected: [],
      loading: %{},
      refresh: %{},
      workflow: %{},
      assigns: %{}
    ]

    @type t :: %__MODULE__{
            query: Query.t() | nil,
            params: map,
            selected: [term],
            loading: map,
            refresh: map,
            workflow: map,
            assigns: map
          }
  end

  defstruct [
    :resource,
    :ui,
    :name,
    :mode,
    :action,
    :recipe,
    :context,
    fields: [],
    intents: [],
    bindings: [],
    queries: [],
    state: nil,
    relationships: [],
    assigns: %{},
    refresh: nil,
    workflow: nil
  ]

  @type mode :: :index | :show | :new | :edit | atom
  @type t :: %__MODULE__{
          resource: module,
          ui: module,
          name: atom,
          mode: mode,
          action: atom | nil,
          recipe: atom,
          context: Context.t(),
          fields: [Field.t()],
          intents: [Intent.t()],
          bindings: [Binding.t()],
          queries: [Query.t()],
          state: State.t() | nil,
          relationships: [term],
          assigns: map,
          refresh: term,
          workflow: term
        }

  @doc """
  Resolves a resource or standalone UI module into a generic view model.

  This is the primary entry point for generated UIs.
  """
  @spec resolve(module, mode, keyword) :: {:ok, __MODULE__.t()} | {:error, term}
  def resolve(ui, mode, opts \\ []) when is_atom(ui) do
    resource = Info.for_resource(ui)
    view_meta = Info.view(ui, mode)
    action = Keyword.get(opts, :action, view_action(view_meta, mode))
    context = Context.new(Keyword.get(opts, :context))
    params = Normalize.mapify(Keyword.get(opts, :params, %{}))

    recipe_overrides =
      RecipeOverrides.normalize_recipe_overrides(Keyword.get(opts, :recipe_overrides, %{}))

    field_overrides =
      recipe_overrides
      |> Map.get(:fields, %{})
      |> RecipeOverrides.merge_override_maps(Keyword.get(opts, :field_overrides, %{}))

    intent_overrides =
      recipe_overrides
      |> Map.get(:intents, %{})
      |> RecipeOverrides.merge_override_maps(Keyword.get(opts, :intent_overrides, %{}))

    query_schema = resolve_query_schema(ui, view_meta, opts)
    query = Query.from_params(params, query_schema)
    bindings = bindings(ui, resource, mode, query, context)

    view = %__MODULE__{
      resource: resource,
      ui: ui,
      name: mode,
      mode: mode,
      action: action,
      recipe: Keyword.get(opts, :recipe, view_recipe(view_meta, mode)),
      context: context,
      fields:
        ui
        |> fields(resource, mode, action)
        |> apply_overrides(field_overrides),
      intents:
        ui
        |> intents(context)
        |> apply_overrides(intent_overrides),
      bindings: bindings,
      queries: Enum.reject([query], &is_nil/1),
      state: %State{
        query: query,
        params: params,
        refresh: normalize_refresh(view_meta),
        workflow: normalize_workflow(view_meta)
      },
      relationships: Ash.Resource.Info.relationships(resource),
      assigns: view_assigns(view_meta, recipe_overrides, Keyword.get(opts, :assigns, %{}), query),
      refresh: normalize_refresh(view_meta),
      workflow: normalize_workflow(view_meta)
    }

    apply_variant_resolvers(view, Keyword.get(opts, :variant_resolvers, []))
  rescue
    error -> {:error, error}
  end

  @doc "Renders a view through the existing recipe system."
  @spec to_layout(t, keyword) :: {:ok, AshSDUI.Layout.Node.t()} | {:error, term}
  def to_layout(%__MODULE__{} = view, opts \\ []) do
    with {:ok, module} <- Registry.fetch(view.recipe) do
      {:ok, module.to_layout(view, opts)}
    end
  end

  @doc "Renders a view through the existing recipe system or raises."
  @spec to_layout!(t, keyword) :: AshSDUI.Layout.Node.t()
  def to_layout!(%__MODULE__{} = view, opts \\ []) do
    case to_layout(view, opts) do
      {:ok, layout} -> layout
      {:error, reason} -> raise ArgumentError, "could not render view layout: #{inspect(reason)}"
    end
  end

  @doc "Renders a view to a renderable tree."
  @spec to_tree(t, keyword) :: {:ok, AshSDUI.Renderer.TreeNode.t()} | {:error, term}
  def to_tree(%__MODULE__{} = view, opts \\ []) do
    with {:ok, layout} <- to_layout(view, opts) do
      {:ok, Builder.to_tree(layout)}
    end
  end

  defp fields(ui, _resource, mode, action) when mode in [:new, :edit] do
    visible_names =
      ui
      |> Info.ui_fields()
      |> Enum.reject(&hidden_for_mode?(&1, mode))
      |> MapSet.new(& &1.name)

    ui
    |> AshSDUI.Form.fields(action)
    |> Enum.filter(&MapSet.member?(visible_names, &1.name))
    |> Enum.map(fn field ->
      source = Enum.find(Info.ui_fields(ui), &(&1.name == field.name))

      %Field{
        name: field.name,
        label: field.label,
        widget: field.widget,
        type: field.type,
        required: field.required,
        input_source: field.input_source,
        relationship: field.relationship,
        relationship_type: field.relationship_type,
        option_label: field.option_label,
        option_value: field.option_value,
        prompt: field.prompt,
        read_action: field.read_action,
        options: field.options || [],
        multiple?: field.multiple? || false,
        order: (source && source.order) || 0,
        hidden: false,
        field_component: field.field_component,
        filter?: false,
        sortable?: false,
        format: nil,
        empty_state: nil,
        badge?: false,
        binding: (source && source.binding) || default_field_binding(mode),
        source: source || field
      }
    end)
  end

  defp fields(ui, resource, mode, _action) do
    ui
    |> Info.ui_fields()
    |> Enum.reject(&hidden_for_mode?(&1, mode))
    |> Enum.sort_by(& &1.order)
    |> Enum.map(fn field ->
      attribute = Ash.Resource.Info.attribute(resource, field.name)

      %Field{
        name: field.name,
        label: Info.resolve_label(field, ui),
        widget: field.widget || infer_widget(attribute),
        type: attribute && attribute.type,
        required: attribute && attribute.allow_nil? == false,
        input_source: :attribute,
        relationship: nil,
        relationship_type: nil,
        option_label: nil,
        option_value: nil,
        prompt: nil,
        read_action: nil,
        options: [],
        multiple?: false,
        order: field.order,
        hidden: field.hidden,
        field_component: field.field_component,
        filter?: field.filter?,
        sortable?: field.sortable?,
        format: field.format,
        empty_state: field.empty_state,
        badge?: field.badge?,
        binding: field.binding || default_field_binding(mode),
        source: field
      }
    end)
  end

  defp intents(ui, context) do
    ui
    |> Info.ui_intents()
    |> Enum.reject(&(&1.requires_actor? && is_nil(context.actor)))
    |> Enum.map(&Intent.resolve(&1, ui))
  end

  defp bindings(ui, resource, mode, query, context) do
    case Info.ui_bindings(ui) do
      [] ->
        [default_binding(resource, mode, query, context)]

      bindings ->
        Enum.map(bindings, fn binding ->
          Binding.resolve(
            %{
              name: binding.name,
              source: binding.source,
              many?: binding.many?,
              query:
                if(binding.query && binding.query == query_name(query),
                  do: query,
                  else: binding.query
                ),
              default: binding.default,
              refresh: Map.get(binding, :refresh),
              update: Map.get(binding, :update)
            },
            context
          )
        end)
    end
  end

  defp normalize_refresh(nil), do: %{}
  defp normalize_refresh(%{refresh: nil}), do: %{}
  defp normalize_refresh(%{refresh: refresh}) when is_map(refresh), do: refresh
  defp normalize_refresh(%{refresh: refresh}), do: %{mode: refresh}

  defp normalize_workflow(nil), do: %{}
  defp normalize_workflow(%{workflow: nil}), do: %{}
  defp normalize_workflow(%{workflow: workflow}) when is_map(workflow), do: workflow
  defp normalize_workflow(%{workflow: workflow}), do: %{state: workflow}

  defp default_binding(resource, :index, query, context) do
    Binding.resolve(
      %{
        name: :collection,
        source: {:resource, resource},
        many?: true,
        query: query
      },
      context
    )
  end

  defp default_binding(resource, mode, query, context) when mode in [:show, :edit] do
    Binding.resolve(
      %{name: :record, source: {:resource, resource}, many?: false, query: query},
      context
    )
  end

  defp default_binding(resource, _mode, _query, context) do
    Binding.resolve(%{name: :record, source: {:resource, resource}, many?: false}, context)
  end

  defp apply_variant_resolvers(view, []), do: {:ok, view}

  defp apply_variant_resolvers(view, [resolver | rest]) when is_function(resolver, 2) do
    case resolver.(view, view.context) do
      {:ok, %__MODULE__{} = view} -> apply_variant_resolvers(view, rest)
      %__MODULE__{} = view -> apply_variant_resolvers(view, rest)
      {:error, reason} -> {:error, reason}
      other -> {:error, {:invalid_variant_resolver_result, other}}
    end
  end

  defp resolve_query_schema(ui, view_meta, opts) do
    query_name =
      Keyword.get(opts, :query) ||
        (view_meta && Map.get(view_meta, :query)) ||
        if(Enum.empty?(Info.ui_queries(ui)), do: nil, else: :default)

    query_name &&
      Enum.find(Info.ui_queries(ui), fn query ->
        query.name == query_name
      end)
  end

  defp query_name(nil), do: nil
  defp query_name(%Query{name: name}), do: name
  defp query_name(name) when is_atom(name), do: name

  defp view_action(%{action: action}, _mode) when is_atom(action) and not is_nil(action),
    do: action

  defp view_action(%{read_action: action}, mode)
       when mode in [:index, :show] and is_atom(action) and not is_nil(action),
       do: action

  defp view_action(_view, :index), do: :read
  defp view_action(_view, :show), do: :read
  defp view_action(_view, :new), do: :create
  defp view_action(_view, :edit), do: :update
  defp view_action(_view, _mode), do: nil

  defp view_recipe(%{recipe: recipe}, _mode) when is_atom(recipe) and not is_nil(recipe),
    do: recipe

  defp view_recipe(_view, :index), do: :collection
  defp view_recipe(_view, :show), do: :detail
  defp view_recipe(_view, :new), do: :form
  defp view_recipe(_view, :edit), do: :form
  defp view_recipe(_view, mode), do: mode

  defp default_field_binding(mode) when mode in [:index], do: nil
  defp default_field_binding(_mode), do: :record

  defp hidden_for_mode?(field, mode) do
    field.hidden || mode_visible?(field, mode) == false
  end

  defp mode_visible?(field, :index), do: visible_flag(field.index?)
  defp mode_visible?(field, :show), do: visible_flag(field.show?)
  defp mode_visible?(field, mode) when mode in [:new, :edit], do: visible_flag(field.form?)
  defp mode_visible?(_field, _mode), do: true

  defp visible_flag(nil), do: true
  defp visible_flag(value), do: value

  defp infer_widget(%{type: Ash.Type.Atom}), do: :text_input
  defp infer_widget(%{type: Ash.Type.String}), do: :text_input
  defp infer_widget(%{type: :string}), do: :text_input
  defp infer_widget(%{type: :utc_datetime}), do: :datetime
  defp infer_widget(_), do: :text_input

  defp apply_overrides(items, overrides) do
    items
    |> Enum.reduce([], fn item, acc ->
      case Map.get(overrides, item.name, %{}) do
        %{skip?: true} ->
          acc

        override ->
          [struct(item, Map.delete(override, :skip?)) | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp view_assigns(view_meta, recipe_overrides, assigns, query) do
    empty_state = RecipeOverrides.normalize_empty_state(Map.get(recipe_overrides, :empty_state))

    %{
      title: Map.get(recipe_overrides, :title) || (view_meta && view_meta.title),
      empty_state: Map.get(empty_state, :title) || (view_meta && view_meta.empty_state),
      empty_state_body: Map.get(empty_state, :body),
      layout: view_meta && view_meta.layout,
      recipe_overrides: recipe_overrides,
      query: query
    }
    |> Map.merge(assigns)
  end
end
