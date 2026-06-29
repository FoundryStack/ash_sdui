defmodule AshSDUI.LiveResource.Render do
  @moduledoc false

  import Phoenix.Component

  alias AshSDUI.Runtime.RecipeOverrides
  alias AshSDUI.Runtime.State, as: RuntimeState

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
      {runtime_banner(assigns)}
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
            <button type="submit" class="btn btn-primary" phx-disable-with="Saving...">
              Save
            </button>
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
      {runtime_banner(assigns)}
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
      {runtime_banner(assigns)}
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

  defp runtime_banner(assigns) do
    pending_count = RuntimeState.pending_count(assigns[:ash_sdui_state])
    offline? = RuntimeState.offline?(assigns[:ash_sdui_state])
    last_error = RuntimeState.last_error(assigns[:ash_sdui_state])

    assigns =
      assigns
      |> assign(:pending_count, pending_count)
      |> assign(:offline?, offline?)
      |> assign(:last_error, last_error)

    ~H"""
    <div :if={@pending_count > 0 || @offline? || @last_error} class="space-y-2">
      <div :if={@pending_count > 0} class="alert alert-info py-2 text-sm">
        <span>{pending_message(@pending_count)}</span>
      </div>

      <div :if={@offline?} class="alert alert-warning py-2 text-sm">
        <span>Working offline. Showing the last known state.</span>
      </div>

      <div :if={@last_error} class="alert alert-error py-2 text-sm">
        <span>{error_message(@last_error)}</span>
      </div>
    </div>
    """
  end

  defp pending_message(1), do: "1 update is syncing."
  defp pending_message(count), do: "#{count} updates are syncing."

  defp error_message(%{reason: reason}) when is_binary(reason), do: reason
  defp error_message(%{reason: reason}), do: inspect(reason)
  defp error_message(reason), do: inspect(reason)
end
