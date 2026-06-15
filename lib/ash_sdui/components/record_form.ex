defmodule AshSDUI.Components.RecordForm do
  @moduledoc """
  DaisyUI-backed form generated from `AshSDUI.Form.fields/2` metadata.
  """

  use Phoenix.Component

  AshSDUI.Registry.register("AshSDUI.RecordForm@v1", __MODULE__, %{
    fragment: "",
    subject_types: []
  })

  def __ash_sdui_component_name__, do: "AshSDUI.RecordForm@v1"
  def __ash_sdui_fragment__, do: ""
  def __ash_sdui_subject_types__, do: []

  attr(:form, :any, required: true)
  attr(:ui, :atom, required: true)
  attr(:action, :atom, required: true)
  attr(:fields, :list, default: nil)
  attr(:view, :any, default: nil)
  attr(:bindings, :map, default: %{})
  attr(:state, :any, default: nil)
  attr(:context, :any, default: nil)
  attr(:change_event, :string, default: "validate")
  attr(:submit_event, :string, default: "save")
  attr(:field_overrides, :map, default: %{})
  attr(:class, :string, default: nil)
  slot(:extra_fields)
  slot(:footer)

  def render(assigns) do
    fields =
      (assigns.fields || AshSDUI.Form.fields(assigns.ui, assigns.action))
      |> Enum.map(&apply_override(&1, Map.get(assigns.field_overrides, &1.name, %{})))

    assigns = assign(assigns, :fields, fields)

    ~H"""
    <form phx-change={@change_event} phx-submit={@submit_event} class={["space-y-5", @class]}>
      <%= for field <- @fields do %>
        <fieldset class="fieldset">
          <legend class="fieldset-legend">
            {field.label}{if field.required, do: " *"}
          </legend>
          <AshSDUI.Components.FieldInput.render form={@form} field={field} />
          <%= for error <- @form[field.name].errors do %>
            <p class="label text-error text-xs">{translate_error(error)}</p>
          <% end %>
        </fieldset>
      <% end %>

      <%= for field <- @extra_fields do %>
        {render_slot(field)}
      <% end %>

      <%= for item <- @footer do %>
        {render_slot(item)}
      <% end %>
    </form>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp apply_override(field, override) do
    Map.merge(field, Enum.into(override, %{}))
  end
end
