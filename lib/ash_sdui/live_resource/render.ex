defmodule AshSDUI.LiveResource.Render do
  @moduledoc false

  import Phoenix.Component

  alias AshSDUI.Runtime.RecipeOverrides

  def render_error(assigns, reason) do
    assigns = assign(assigns, :reason, inspect(reason))

    ~H"""
    <div class="alert alert-error">{@reason}</div>
    """
  end

  def render_tree(assigns) do
    ~H"""
      <AshSDUI.Components.SDUIRoot.render
        tree={@__sdui_tree__}
        view={@ash_sdui_view}
        bindings={@ash_sdui_bindings}
        state={@ash_sdui_state}
        context={@ash_sdui_view.context}
        domain={AshSDUI.LiveResource.root_domain(@ash_sdui_resource, @ash_sdui_opts)}
      />
    """
  end

  def render_form(assigns) do
    assigns =
      assign(
        assigns,
        :content_class,
        RecipeOverrides.recipe_class(assigns.ash_sdui_view, :content)
      )

    ~H"""
    <div class="space-y-6">
      <AshSDUI.Components.RecordForm.render
        form={@form}
        ui={@ash_sdui_ui}
        view={@ash_sdui_view}
        action={@ash_sdui_view.action}
        fields={@ash_sdui_view.fields}
        nested_forms={@ash_sdui_view.nested_forms}
        bindings={@ash_sdui_bindings}
        state={@ash_sdui_state}
        context={@ash_sdui_context}
        class={@content_class}
      >
        <:footer>
          <div class="flex justify-end">
            <button type="submit" class="btn btn-primary">Save</button>
          </div>
        </:footer>
      </AshSDUI.Components.RecordForm.render>
    </div>
    """
  end

  def render_show(assigns) do
    assigns =
      assigns
      |> assign(:toolbar_hidden?, RecipeOverrides.recipe_hidden?(assigns.ash_sdui_view, :toolbar))
      |> assign(:toolbar_class, RecipeOverrides.recipe_class(assigns.ash_sdui_view, :toolbar))
      |> assign(:content_class, RecipeOverrides.recipe_class(assigns.ash_sdui_view, :content))

    ~H"""
    <div class="space-y-6">
      <AshSDUI.Components.IntentBar.render
        :if={!@toolbar_hidden?}
        ui={@ash_sdui_ui}
        view={@ash_sdui_view}
        subject={@subject}
        intents={@ash_sdui_view.intents}
        bindings={@ash_sdui_bindings}
        state={@ash_sdui_state}
        context={@ash_sdui_context}
        placement={:toolbar}
        class={@toolbar_class}
      />
      <AshSDUI.Components.RecordDetail.render
        subject={@subject}
        fields={@ash_sdui_view.fields}
        bindings={@ash_sdui_bindings}
        class={@content_class}
      />
    </div>
    """
  end

  def render_index(assigns) do
    assigns =
      assigns
      |> assign(:toolbar_hidden?, RecipeOverrides.recipe_hidden?(assigns.ash_sdui_view, :toolbar))
      |> assign(:toolbar_class, RecipeOverrides.recipe_class(assigns.ash_sdui_view, :toolbar))
      |> assign(:content_class, RecipeOverrides.recipe_class(assigns.ash_sdui_view, :content))

    ~H"""
    <div class="space-y-6">
      <AshSDUI.Components.IntentBar.render
        :if={!@toolbar_hidden?}
        ui={@ash_sdui_ui}
        view={@ash_sdui_view}
        intents={@ash_sdui_view.intents}
        bindings={@ash_sdui_bindings}
        state={@ash_sdui_state}
        context={@ash_sdui_context}
        placement={:toolbar}
        class={@toolbar_class}
      />
      <AshSDUI.Components.RecordList.render
        records={@records}
        fields={@ash_sdui_view.fields}
        intents={@ash_sdui_view.intents}
        ui={@ash_sdui_ui}
        view={@ash_sdui_view}
        bindings={@ash_sdui_bindings}
        state={@ash_sdui_state}
        context={@ash_sdui_context}
        empty_title={@ash_sdui_view.assigns[:empty_state] || "No records"}
        empty_body={@ash_sdui_view.assigns[:empty_state_body]}
        class={@content_class}
      />
    </div>
    """
  end
end
