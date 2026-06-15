defmodule AshSDUI.Components.FieldValue do
  @moduledoc """
  Small display formatter for generated resource detail and collection views.
  """

  use Phoenix.Component

  attr(:subject, :any, default: nil)
  attr(:field, :map, required: true)
  attr(:bindings, :map, default: %{})

  def render(assigns) do
    value =
      assigns.subject
      |> subject_for_field(assigns.field, assigns.bindings)
      |> value(assigns.field.name)

    assigns = assign(assigns, :display_value, format_value(value, assigns.field))

    ~H"""
    <%= if Map.get(@field, :badge?, false) do %>
      <span class="badge badge-outline">{@display_value}</span>
    <% else %>
      <span>{@display_value}</span>
    <% end %>
    """
  end

  defp subject_for_field(_subject, %{binding: binding}, bindings) when is_atom(binding) do
    Map.get(bindings, binding)
  end

  defp subject_for_field(subject, _field, _bindings), do: subject
  defp value(subject, name) when is_map(subject), do: Map.get(subject, name)
  defp value(subject, name), do: Map.get(subject, name)

  defp format_value(nil, field), do: Map.get(field, :empty_state) || "-"
  defp format_value("", field), do: Map.get(field, :empty_state) || "-"

  defp format_value(%DateTime{} = value, %{format: :relative_datetime}),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M")

  defp format_value(value, _field), do: to_string(value)
end
