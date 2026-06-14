defmodule AshSDUI.Screen do
  @moduledoc """
  Generic intermediate representation for an Ash-backed UI screen.

  A screen is resolved from Ash resource metadata plus SDUI presentation metadata.
  Layout recipes consume this struct and produce concrete `AshSDUI.Layout.Node`
  trees. Keeping this layer separate prevents built-in presets, DaisyUI, or app
  roles from becoming hardcoded framework concepts.
  """

  alias AshSDUI.Context
  alias AshSDUI.Layout
  alias AshSDUI.LayoutRecipe.Registry
  alias AshSDUI.Resource.Info

  defmodule Field do
    @moduledoc false
    defstruct [
      :name,
      :label,
      :widget,
      :type,
      :required,
      :order,
      :hidden,
      :field_component,
      :filter?,
      :sortable?,
      :format,
      :empty_state,
      :badge?,
      :source
    ]

    @type t :: %__MODULE__{
            name: atom,
            label: String.t(),
            widget: atom | nil,
            type: term,
            required: boolean,
            order: non_neg_integer,
            hidden: boolean,
            field_component: module | nil,
            filter?: boolean,
            sortable?: boolean,
            format: atom | nil,
            empty_state: String.t() | nil,
            badge?: boolean,
            source: term
          }
  end

  defmodule Action do
    @moduledoc false
    defstruct [
      :name,
      :label,
      :intent,
      :icon,
      :component_override,
      :kind,
      :to,
      :event,
      :confirm,
      :placement,
      :requires_actor?,
      :visible_when,
      :source
    ]

    @type t :: %__MODULE__{
            name: atom,
            label: String.t(),
            intent: atom,
            icon: String.t() | nil,
            component_override: String.t() | nil,
            kind: :link | :event | :submit | nil,
            to: String.t() | nil,
            event: String.t() | nil,
            confirm: boolean | String.t() | nil,
            placement: atom | nil,
            requires_actor?: boolean,
            visible_when: atom | nil,
            source: term
          }
  end

  defstruct [
    :resource,
    :resource_ui,
    :mode,
    :action,
    :recipe,
    :context,
    fields: [],
    actions: [],
    relationships: [],
    assigns: %{}
  ]

  @type mode :: :index | :show | :new | :edit | atom
  @type t :: %__MODULE__{
          resource: module,
          resource_ui: module,
          mode: mode,
          action: atom | nil,
          recipe: atom,
          context: Context.t(),
          fields: [Field.t()],
          actions: [Action.t()],
          relationships: [term],
          assigns: map
        }

  @doc """
  Resolves a resource or standalone UI module into a screen.

  Options:
  - `:action` overrides the conventional action for the mode.
  - `:recipe` chooses the recipe name used by `to_layout/2`.
  - `:context` accepts an `AshSDUI.Context`, map, or keyword list.
  - `:recipe_overrides` applies presentational overrides for the built-in recipes.
    Supported keys include `:title`, `:empty_state`, `:toolbar`, `:content`,
    plus nested `:fields` / `:actions` maps for low-boilerplate screen tweaks.
  - `:field_overrides` applies per-field overrides keyed by field name. Use `false`
    to hide a field.
  - `:action_overrides` applies per-action overrides keyed by action name. Use
    `false` to hide an action.
  - `:variant_resolvers` is a list of functions that can transform the screen.
  """
  @spec resolve(module, mode, keyword) :: {:ok, t} | {:error, term}
  def resolve(resource_or_ui, mode, opts \\ []) when is_atom(resource_or_ui) do
    resource = Info.for_resource(resource_or_ui)
    screen_meta = Info.screen(resource_or_ui, mode)
    action = Keyword.get(opts, :action, screen_action(screen_meta, mode))
    context = Context.new(Keyword.get(opts, :context))
    recipe_overrides = normalize_recipe_overrides(Keyword.get(opts, :recipe_overrides, %{}))

    field_overrides =
      recipe_overrides
      |> Map.get(:fields, %{})
      |> merge_override_maps(Keyword.get(opts, :field_overrides, %{}))

    action_overrides =
      recipe_overrides
      |> Map.get(:actions, %{})
      |> merge_override_maps(Keyword.get(opts, :action_overrides, %{}))

    screen = %__MODULE__{
      resource: resource,
      resource_ui: resource_or_ui,
      mode: mode,
      action: action,
      recipe: Keyword.get(opts, :recipe, screen_recipe(screen_meta, mode)),
      context: context,
      fields:
        resource_or_ui
        |> fields(resource, mode, action)
        |> apply_overrides(field_overrides),
      actions:
        resource_or_ui
        |> actions(context)
        |> apply_overrides(action_overrides),
      relationships: Ash.Resource.Info.relationships(resource),
      assigns: screen_assigns(screen_meta, recipe_overrides, Keyword.get(opts, :assigns, %{}))
    }

    apply_variant_resolvers(screen, Keyword.get(opts, :variant_resolvers, []))
  rescue
    error -> {:error, error}
  end

  @doc "Converts a screen to a layout tree with its configured recipe."
  @spec to_layout(t, keyword) :: {:ok, Layout.Node.t()} | {:error, term}
  def to_layout(%__MODULE__{recipe: recipe} = screen, opts \\ []) do
    with {:ok, module} <- Registry.fetch(recipe) do
      {:ok, module.to_layout(screen, opts)}
    end
  end

  @doc "Converts a screen to a layout tree or raises."
  @spec to_layout!(t, keyword) :: Layout.Node.t()
  def to_layout!(%__MODULE__{} = screen, opts \\ []) do
    case to_layout(screen, opts) do
      {:ok, layout} ->
        layout

      {:error, reason} ->
        raise ArgumentError, "could not render screen layout: #{inspect(reason)}"
    end
  end

  defp fields(resource_or_ui, _resource, mode, action) when mode in [:new, :edit] do
    visible_names =
      resource_or_ui
      |> Info.ui_attributes()
      |> Enum.reject(&hidden_for_mode?(&1, mode))
      |> MapSet.new(& &1.name)

    resource_or_ui
    |> AshSDUI.Form.fields(action)
    |> Enum.filter(&MapSet.member?(visible_names, &1.name))
    |> Enum.map(fn field ->
      %Field{
        name: field.name,
        label: field.label,
        widget: field.widget,
        type: field.type,
        required: field.required,
        order: field[:order] || 0,
        hidden: false,
        field_component: field.field_component,
        filter?: false,
        sortable?: false,
        format: nil,
        empty_state: nil,
        badge?: false,
        source: field
      }
    end)
  end

  defp fields(resource_or_ui, resource, mode, _action) do
    resource_or_ui
    |> Info.ui_attributes()
    |> Enum.reject(&hidden_for_mode?(&1, mode))
    |> Enum.sort_by(& &1.order)
    |> Enum.map(fn attr ->
      attribute = Ash.Resource.Info.attribute(resource, attr.name)

      %Field{
        name: attr.name,
        label: Info.resolve_label(attr, resource_or_ui),
        widget: attr.widget || infer_widget(attribute),
        type: attribute && attribute.type,
        required: attribute && attribute.allow_nil? == false,
        order: attr.order,
        hidden: attr.hidden,
        field_component: attr.field_component,
        filter?: attr.filter?,
        sortable?: attr.sortable?,
        format: attr.format,
        empty_state: attr.empty_state,
        badge?: attr.badge?,
        source: attr
      }
    end)
  end

  defp actions(resource_or_ui, context) do
    resource_or_ui
    |> Info.ui_actions()
    |> Enum.reject(&(&1.requires_actor? && is_nil(context.actor)))
    |> Enum.map(fn action ->
      %Action{
        name: action.name,
        label: Info.resolve_label(action, resource_or_ui),
        intent: action.intent,
        icon: action.icon,
        component_override: action.component_override,
        kind: action.kind,
        to: action.to,
        event: action.event,
        confirm: action.confirm,
        placement: action.placement,
        requires_actor?: action.requires_actor?,
        visible_when: action.visible_when,
        source: action
      }
    end)
  end

  defp apply_variant_resolvers(screen, []), do: {:ok, screen}

  defp apply_variant_resolvers(screen, [resolver | rest]) when is_function(resolver, 2) do
    case resolver.(screen, screen.context) do
      {:ok, %__MODULE__{} = screen} -> apply_variant_resolvers(screen, rest)
      %__MODULE__{} = screen -> apply_variant_resolvers(screen, rest)
      {:error, reason} -> {:error, reason}
      other -> {:error, {:invalid_variant_resolver_result, other}}
    end
  end

  defp screen_action(%{action: action}, _mode) when is_atom(action) and not is_nil(action),
    do: action

  defp screen_action(%{read_action: action}, mode)
       when mode in [:index, :show] and is_atom(action) and not is_nil(action),
       do: action

  defp screen_action(_screen, :index), do: :read
  defp screen_action(_screen, :show), do: :read
  defp screen_action(_screen, :new), do: :create
  defp screen_action(_screen, :edit), do: :update
  defp screen_action(_screen, _mode), do: nil

  defp screen_recipe(%{recipe: recipe}, _mode) when is_atom(recipe) and not is_nil(recipe),
    do: recipe

  defp screen_recipe(_screen, :index), do: :collection
  defp screen_recipe(_screen, :show), do: :detail
  defp screen_recipe(_screen, :new), do: :form
  defp screen_recipe(_screen, :edit), do: :form
  defp screen_recipe(_screen, mode), do: mode

  defp hidden_for_mode?(attr, mode) do
    attr.hidden || mode_visible?(attr, mode) == false
  end

  defp mode_visible?(attr, :index), do: visible_flag(attr.index?)
  defp mode_visible?(attr, :show), do: visible_flag(attr.show?)
  defp mode_visible?(attr, mode) when mode in [:new, :edit], do: visible_flag(attr.form?)
  defp mode_visible?(_attr, _mode), do: true

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

  defp screen_assigns(screen_meta, recipe_overrides, assigns) do
    empty_state = normalize_empty_state(Map.get(recipe_overrides, :empty_state))

    %{
      title: Map.get(recipe_overrides, :title) || (screen_meta && screen_meta.title),
      empty_state: Map.get(empty_state, :title) || (screen_meta && screen_meta.empty_state),
      empty_state_body: Map.get(empty_state, :body),
      layout: screen_meta && screen_meta.layout,
      recipe_overrides: recipe_overrides
    }
    |> Map.merge(assigns)
  end

  defp merge_override_maps(base, override) do
    base
    |> normalize_override_map()
    |> Map.merge(normalize_override_map(override))
  end

  defp normalize_override_map(overrides) when is_list(overrides) do
    overrides
    |> Enum.into(%{})
    |> normalize_override_map()
  end

  defp normalize_override_map(overrides) when is_map(overrides) do
    Map.new(overrides, fn {key, override} ->
      {key, normalize_override(override)}
    end)
  end

  defp normalize_override_map(_overrides), do: %{}

  defp normalize_recipe_overrides(overrides) when is_list(overrides) do
    overrides
    |> Enum.into(%{})
    |> normalize_recipe_overrides()
  end

  defp normalize_recipe_overrides(overrides) when is_map(overrides) do
    %{
      fields: normalize_override_map(Map.get(overrides, :fields, %{})),
      actions: normalize_override_map(Map.get(overrides, :actions, %{})),
      toolbar: normalize_override(Map.get(overrides, :toolbar, %{})),
      content: normalize_override(Map.get(overrides, :content, %{})),
      screen: normalize_override(Map.get(overrides, :screen, %{})),
      title: Map.get(overrides, :title),
      empty_state: normalize_empty_state(Map.get(overrides, :empty_state))
    }
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}] end)
    |> Enum.into(%{})
  end

  defp normalize_recipe_overrides(_overrides), do: %{}

  defp normalize_empty_state(nil), do: %{}
  defp normalize_empty_state(empty_state) when is_binary(empty_state), do: %{title: empty_state}

  defp normalize_empty_state(empty_state) when is_list(empty_state),
    do: Enum.into(empty_state, %{})

  defp normalize_empty_state(empty_state) when is_map(empty_state), do: empty_state
  defp normalize_empty_state(_empty_state), do: %{}

  defp normalize_override(false), do: %{skip?: true}
  defp normalize_override(nil), do: %{}
  defp normalize_override(true), do: %{}
  defp normalize_override(override) when is_list(override), do: Enum.into(override, %{})
  defp normalize_override(override) when is_map(override), do: override
  defp normalize_override(_override), do: %{}
end
