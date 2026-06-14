defmodule AshSDUI.Recipes.GenericResource do
  @moduledoc """
  Built-in generic recipe for Ash resource screens.

  This recipe emits semantic SDUI nodes instead of DaisyUI-specific markup. A
  renderer or application can map these component names to DaisyUI, custom app
  components, or another design system.
  """

  @behaviour AshSDUI.LayoutRecipe

  alias AshSDUI.Layout.Builder
  alias AshSDUI.Screen

  @impl true
  def to_layout(%Screen{} = screen, _opts) do
    recipe_overrides = screen.assigns[:recipe_overrides] || %{}
    screen_override = Map.get(recipe_overrides, :screen, %{})

    Builder.node(Map.get(screen_override, :component, "AshSDUI.GenericScreen@v1"),
      id: root_id(screen),
      static_props: Map.merge(screen_props(screen), Map.get(screen_override, :props, %{})),
      children: children(screen, recipe_overrides)
    )
  end

  defp children(%Screen{mode: mode} = screen, recipe_overrides) when mode in [:new, :edit] do
    [
      action_bar(screen, recipe_overrides, 0),
      content_node(screen, recipe_overrides, "AshSDUI.ResourceForm@v1", 1)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp children(%Screen{mode: :index} = screen, recipe_overrides) do
    [
      action_bar(screen, recipe_overrides, 0),
      content_node(screen, recipe_overrides, "AshSDUI.ResourceCollection@v1", 1)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp children(%Screen{} = screen, recipe_overrides) do
    [
      action_bar(screen, recipe_overrides, 0),
      content_node(screen, recipe_overrides, "AshSDUI.ResourceDetail@v1", 1)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp action_bar(screen, recipe_overrides, order) do
    override = Map.get(recipe_overrides, :toolbar, %{})

    unless Map.get(override, :skip?, false) do
      Builder.node(Map.get(override, :component, "AshSDUI.ActionBar@v1"),
        id: "#{root_id(screen)}-actions",
        region: :toolbar,
        order: Map.get(override, :order, order),
        static_props:
          %{actions: Enum.map(screen.actions, &action_props/1)}
          |> Map.merge(Map.get(override, :props, %{}))
      )
    end
  end

  defp content_node(screen, recipe_overrides, component, order) do
    override = Map.get(recipe_overrides, :content, %{})

    Builder.node(Map.get(override, :component, component),
      id: "#{root_id(screen)}-content",
      region: :content,
      order: Map.get(override, :order, order),
      subject_resource: screen.resource,
      static_props:
        content_props(screen)
        |> Map.merge(Map.get(override, :props, %{}))
    )
  end

  defp screen_props(screen) do
    %{
      resource: inspect(screen.resource),
      resource_ui: inspect(screen.resource_ui),
      mode: screen.mode,
      action: screen.action,
      recipe: screen.recipe,
      title: screen.assigns[:title],
      empty_state_title: screen.assigns[:empty_state],
      empty_state_body: screen.assigns[:empty_state_body],
      context: context_props(screen.context)
    }
  end

  defp content_props(screen) do
    %{
      resource: inspect(screen.resource),
      resource_ui: inspect(screen.resource_ui),
      mode: screen.mode,
      action: screen.action,
      title: screen.assigns[:title],
      empty_title: screen.assigns[:empty_state],
      empty_body: screen.assigns[:empty_state_body],
      fields: Enum.map(screen.fields, &field_props/1)
    }
  end

  defp field_props(field) do
    %{
      name: field.name,
      label: field.label,
      widget: field.widget,
      type: type_name(field.type),
      required: field.required,
      order: field.order,
      filter?: field.filter?,
      sortable?: field.sortable?,
      format: field.format,
      empty_state: field.empty_state,
      badge?: field.badge?
    }
  end

  defp action_props(action) do
    %{
      name: action.name,
      label: action.label,
      intent: action.intent,
      icon: action.icon,
      component_override: action.component_override,
      kind: action.kind,
      to: action.to,
      event: action.event,
      confirm: action.confirm,
      placement: action.placement,
      requires_actor?: action.requires_actor?,
      visible_when: action.visible_when
    }
  end

  defp context_props(context) do
    %{
      tenant: context.tenant,
      locale: context.locale,
      audience: context.audience,
      device: context.device
    }
  end

  defp root_id(%Screen{resource: resource, mode: mode}) do
    resource
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> then(&"#{&1}-#{mode}")
  end

  defp type_name(nil), do: nil
  defp type_name(type) when is_atom(type), do: inspect(type)
  defp type_name(type), do: inspect(type)
end
