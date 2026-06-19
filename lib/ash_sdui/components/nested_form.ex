defmodule AshSDUI.Components.NestedForm do
  @moduledoc """
  Recursive renderer for metadata-driven nested AshPhoenix forms.
  """

  use Phoenix.Component

  attr(:form, :any, required: true)
  attr(:nested_form, :map, required: true)

  def render(assigns) do
    assigns =
      assigns
      |> assign(:section_path, section_path(assigns.form, assigns.nested_form))
      |> assign(:single?, assigns.nested_form.style == :single)

    ~H"""
    <section class="space-y-4 rounded-box border border-base-300 bg-base-100 p-4">
      <div class="flex items-center justify-between gap-3">
        <div>
          <h3 class="text-sm font-semibold">{@nested_form.label}</h3>
          <p class="text-xs text-base-content/70">{humanize_mode(@nested_form.interaction_mode)}</p>
        </div>
        <button
          :if={@nested_form.allow_add?}
          type="button"
          class="btn btn-outline btn-sm"
          phx-click="nested_add_form"
          phx-value-path={@section_path}
        >
          {add_label(@nested_form)}
        </button>
      </div>

      <.inputs_for :let={child_form} field={@form[@nested_form.name]}>
        <div class="space-y-4 rounded-box bg-base-200/40 p-4">
          <div class="flex items-center justify-between gap-3">
            <p class="text-sm font-medium">
              {entry_label(@nested_form, child_form.index)}
            </p>
            <div class="flex items-center gap-2">
              <button
                :if={@nested_form.allow_sort? && !@single?}
                type="button"
                class="btn btn-ghost btn-xs"
                phx-click="nested_sort_form"
                phx-value-path={child_form.name}
                phx-value-direction="decrement"
              >
                Up
              </button>
              <button
                :if={@nested_form.allow_sort? && !@single?}
                type="button"
                class="btn btn-ghost btn-xs"
                phx-click="nested_sort_form"
                phx-value-path={child_form.name}
                phx-value-direction="increment"
              >
                Down
              </button>
              <button
                :if={@nested_form.allow_remove?}
                type="button"
                class="btn btn-ghost btn-xs text-error"
                phx-click="nested_remove_form"
                phx-value-path={child_form.name}
              >
                Remove
              </button>
            </div>
          </div>

          <%= for field <- @nested_form.fields do %>
            <fieldset class="fieldset">
              <legend class="fieldset-legend">
                {field.label}{if field.required, do: " *"}
              </legend>
              <AshSDUI.Components.FieldInput.render form={child_form} field={field} />
              <%= for error <- child_form[field.name].errors do %>
                <p class="label text-error text-xs">
                  {AshSDUI.Components.RecordForm.translate_error(error)}
                </p>
              <% end %>
            </fieldset>
          <% end %>

          <AshSDUI.Components.NestedForm.render :for={child_nested <- @nested_form.nested_forms} form={child_form} nested_form={child_nested} />
        </div>
      </.inputs_for>
    </section>
    """
  end

  defp section_path(form, nested_form), do: form.name <> "[#{nested_form.name}]"

  defp add_label(nested_form) do
    if nested_form.style == :single do
      "Add #{nested_form.label}"
    else
      "Add item"
    end
  end

  defp entry_label(nested_form, nil), do: nested_form.label
  defp entry_label(nested_form, index), do: "#{nested_form.label} #{index + 1}"

  defp humanize_mode(nil), do: "Nested relationship"

  defp humanize_mode(mode) do
    mode
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> :string.titlecase()
    |> to_string()
  end
end
