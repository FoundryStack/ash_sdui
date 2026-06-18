defmodule AshSDUI.Recipes.GenericResource do
  @moduledoc """
  Built-in generic recipe for Ash-backed views.

  This recipe emits semantic SDUI nodes instead of DaisyUI-specific markup. A
  renderer or application can map these component names to DaisyUI, custom app
  components, or another design system.
  """

  @behaviour AshSDUI.LayoutRecipe

  alias AshSDUI.Layout.Builder
  alias AshSDUI.View

  @impl true
  def to_layout(%View{} = view, opts) do
    recipe_overrides = view.assigns[:recipe_overrides] || %{}
    view_override = Map.get(recipe_overrides, :view, %{})

    Builder.node(Map.get(view_override, :component, "AshSDUI.GenericView@v1"),
      id: root_id(view),
      static_props: Map.merge(view_props(view, opts), Map.get(view_override, :props, %{})),
      children: children(view, recipe_overrides, opts)
    )
  end

  defp children(%View{mode: mode} = view, recipe_overrides, opts) when mode in [:new, :edit] do
    [
      intent_bar(view, recipe_overrides, opts, 0),
      content_node(view, recipe_overrides, opts, "AshSDUI.RecordForm@v1", 1)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp children(%View{mode: :index} = view, recipe_overrides, opts) do
    [
      intent_bar(view, recipe_overrides, opts, 0),
      content_node(view, recipe_overrides, opts, "AshSDUI.RecordList@v1", 1)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp children(%View{} = view, recipe_overrides, opts) do
    [
      intent_bar(view, recipe_overrides, opts, 0),
      content_node(view, recipe_overrides, opts, "AshSDUI.RecordDetail@v1", 1)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp intent_bar(view, recipe_overrides, opts, order) do
    override = Map.get(recipe_overrides, :toolbar, %{})

    unless Map.get(override, :skip?, false) do
      Builder.node(Map.get(override, :component, "AshSDUI.IntentBar@v1"),
        id: "#{root_id(view)}-intents",
        region: :toolbar,
        order: Map.get(override, :order, order),
        static_props:
          shared_props(view, opts)
          |> Map.merge(%{
            intents: Enum.map(view.intents, &intent_props/1),
            subject: primary_record(view, opts)
          })
          |> Map.merge(Map.get(override, :props, %{}))
      )
    end
  end

  defp content_node(view, recipe_overrides, opts, component, order) do
    override = Map.get(recipe_overrides, :content, %{})

    Builder.node(Map.get(override, :component, component),
      id: "#{root_id(view)}-content",
      region: :content,
      order: Map.get(override, :order, order),
      subject_resource: view.resource,
      static_props:
        content_props(view, opts)
        |> Map.merge(Map.get(override, :props, %{}))
    )
  end

  defp view_props(view, opts) do
    shared_props(view, opts)
    |> Map.merge(%{
      resource: inspect(view.resource),
      mode: view.mode,
      recipe: view.recipe,
      title: view.assigns[:title],
      empty_state_title: view.assigns[:empty_state],
      empty_state_body: view.assigns[:empty_state_body]
    })
  end

  defp content_props(view, opts) do
    shared_props(view, opts)
    |> Map.merge(%{
      resource: inspect(view.resource),
      mode: view.mode,
      title: view.assigns[:title],
      empty_title: view.assigns[:empty_state],
      empty_body: view.assigns[:empty_state_body],
      fields: Enum.map(view.fields, &field_props/1),
      intents: Enum.map(view.intents, &intent_props/1),
      records: primary_collection(view, opts),
      subject: primary_record(view, opts),
      form: opts[:form]
    })
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
      badge?: field.badge?,
      binding: field.binding
    }
  end

  defp intent_props(intent) do
    %{
      name: intent.name,
      label: intent.label,
      style: intent.style,
      icon: intent.icon,
      component_override: intent.component_override,
      target: intent.target,
      confirm: intent.confirm,
      placement: intent.placement,
      requires_actor?: intent.requires_actor?,
      visible_when: intent.visible_when,
      enabled_when: intent.enabled_when,
      loading_when: intent.loading_when,
      refreshes: intent.refreshes
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

  defp shared_props(view, opts) do
    %{
      view: view,
      ui: view.ui,
      action: view.action,
      bindings: opts[:bindings] || %{},
      state: opts[:state] || view.state,
      context: context_props(opts[:context] || view.context)
    }
  end

  defp primary_collection(view, opts) do
    bindings = opts[:bindings] || %{}

    view.bindings
    |> Enum.find(& &1.many?)
    |> then(fn
      nil -> nil
      binding -> Map.get(bindings, binding.name)
    end)
  end

  defp primary_record(view, opts) do
    bindings = opts[:bindings] || %{}

    view.bindings
    |> Enum.find(&(not &1.many?))
    |> then(fn
      nil -> nil
      binding -> Map.get(bindings, binding.name)
    end)
  end

  defp root_id(%View{resource: resource, mode: mode}) do
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
