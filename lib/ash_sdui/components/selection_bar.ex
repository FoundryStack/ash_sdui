defmodule AshSDUI.Components.SelectionBar do
  @moduledoc """
  Generic selection summary and action tray.
  """

  use Phoenix.Component

  AshSDUI.Registry.register("AshSDUI.SelectionBar@v1", __MODULE__, %{
    fragment: "",
    subject_types: []
  })

  def __ash_sdui_component_name__, do: "AshSDUI.SelectionBar@v1"
  def __ash_sdui_fragment__, do: ""
  def __ash_sdui_subject_types__, do: []

  attr(:count, :integer, default: nil)
  attr(:label, :string, default: "selected")
  attr(:class, :string, default: nil)
  slot(:inner_block)

  def render(assigns) do
    count = assigns.count || infer_count(assigns)

    assigns =
      assigns
      |> assign(:count, count)
      |> assign(:rendered_children, rendered_children(assigns))

    ~H"""
    <section
      :if={@count > 0}
      class={["flex flex-wrap items-center justify-between gap-3 rounded-box border border-base-300 bg-base-100 px-4 py-3", @class]}
      data-testid="selection-bar"
    >
      <p class="text-sm font-medium">
        <span class="font-semibold">{@count}</span> {@label}
      </p>
      <div class="flex flex-wrap items-center gap-2">
        {render_slot(@inner_block)}
        <%= for child <- @rendered_children do %>
          {child}
        <% end %>
      </div>
    </section>
    """
  end

  defp infer_count(assigns) do
    selection =
      nested_value(assigns, :state, :selected) ||
        nested_value(assigns, :state_slice, :selected) ||
        Map.get(assigns, :bound_value) ||
        []

    length(List.wrap(selection))
  end

  defp rendered_children(assigns) do
    assigns
    |> Map.get(:children, %{})
    |> Map.values()
    |> List.flatten()
  end

  defp nested_value(assigns, outer_key, inner_key) do
    case Map.get(assigns, outer_key) do
      %{^inner_key => value} -> value
      struct when is_struct(struct) -> Map.get(struct, inner_key)
      _ -> nil
    end
  end
end
