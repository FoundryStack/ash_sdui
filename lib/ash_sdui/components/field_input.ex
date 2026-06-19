defmodule AshSDUI.Components.FieldInput do
  @moduledoc """
  DaisyUI-backed input renderer for metadata-driven AshSDUI forms.
  """

  use Phoenix.Component

  attr(:form, :any, required: true)
  attr(:field, :map, required: true)
  attr(:class, :string, default: nil)

  def render(assigns) do
    field = assigns.field
    value = Phoenix.HTML.Form.input_value(assigns.form, field.name)
    errors = assigns.form[field.name].errors

    assigns =
      assigns
      |> assign(:value, value)
      |> assign(:errors, errors)
      |> assign(:input, assigns.form[field.name])

    ~H"""
    <%= if Map.get(@field, :field_component) do %>
      {@field.field_component.render(%{
        form: @form,
        field: @field,
        value: @value,
        errors: @errors,
        __changed__: nil
      })}
    <% else %>
      <.default_input input={@input} field={@field} value={@value} errors={@errors} class={@class} />
    <% end %>
    """
  end

  attr(:input, :any, required: true)
  attr(:field, :map, required: true)
  attr(:value, :any, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: nil)

  def default_input(%{field: %{widget: :textarea}} = assigns) do
    ~H"""
    <textarea
      name={@input.name}
      class={["textarea textarea-bordered w-full h-48", @errors != [] && "textarea-error", @class]}
      phx-debounce="300"
    ><%= @value %></textarea>
    """
  end

  def default_input(%{field: %{widget: :checkbox}} = assigns) do
    checked? = assigns.value in [true, "true", "on", 1, "1"]
    assigns = assign(assigns, :checked?, checked?)

    ~H"""
    <input
      type="checkbox"
      name={@input.name}
      value="true"
      checked={@checked?}
      class={["checkbox", @errors != [] && "checkbox-error", @class]}
    />
    """
  end

  def default_input(%{field: %{widget: :email}} = assigns), do: text_input(assigns, "email")

  def default_input(%{field: %{widget: :datetime}} = assigns),
    do: text_input(assigns, "datetime-local")

  def default_input(%{field: %{widget: :select}} = assigns) do
    assigns =
      assigns
      |> assign(:prompt, Map.get(assigns.field, :prompt))
      |> assign(:options, Map.get(assigns.field, :options, []))

    ~H"""
    <select
      name={@input.name}
      class={["select select-bordered w-full", @errors != [] && "select-error", @class]}
    >
      <option :if={@prompt} value="">{@prompt}</option>
      {Phoenix.HTML.Form.options_for_select(@options, @value)}
    </select>
    """
  end

  def default_input(%{field: %{widget: :multiselect}} = assigns) do
    selected =
      assigns.value
      |> List.wrap()
      |> Enum.reject(&(&1 in [nil, ""]))

    assigns =
      assigns
      |> assign(:selected, selected)
      |> assign(:options, Map.get(assigns.field, :options, []))

    ~H"""
    <select
      name={@input.name <> "[]"}
      multiple
      class={["select select-bordered w-full min-h-40", @errors != [] && "select-error", @class]}
    >
      {Phoenix.HTML.Form.options_for_select(@options, @selected)}
    </select>
    """
  end

  def default_input(assigns), do: text_input(assigns, "text")

  defp text_input(assigns, type) do
    assigns = assign(assigns, :type, type)

    ~H"""
    <input
      type={@type}
      name={@input.name}
      value={@value}
      class={["input input-bordered w-full", @errors != [] && "input-error", @class]}
      phx-debounce="300"
    />
    """
  end
end
