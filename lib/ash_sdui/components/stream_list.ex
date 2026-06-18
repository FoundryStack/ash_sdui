defmodule AshSDUI.Components.StreamList do
  @moduledoc """
  Generic live collection renderer for append/merge/remove runtime bindings.
  """

  use Phoenix.Component

  AshSDUI.Registry.register("AshSDUI.StreamList@v1", __MODULE__, %{
    fragment: "",
    subject_types: []
  })

  def __ash_sdui_component_name__, do: "AshSDUI.StreamList@v1"
  def __ash_sdui_fragment__, do: ""
  def __ash_sdui_subject_types__, do: []

  attr(:records, :list, default: [])
  attr(:items, :list, default: nil)
  attr(:bound_value, :any, default: nil)
  attr(:title, :string, default: nil)
  attr(:empty_title, :string, default: "No items")
  attr(:empty_body, :string, default: nil)
  attr(:binding_name, :atom, default: :collection)
  attr(:state, :any, default: nil)
  attr(:class, :string, default: nil)

  def render(assigns) do
    assigns =
      assigns
      |> assign(:items, assigns.items || assigns.bound_value || assigns.records || [])
      |> assign(:refresh_meta, refresh_meta(assigns.state, assigns.binding_name))

    ~H"""
    <section class={["space-y-4", @class]} data-testid="stream-list">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 :if={@title} class="text-2xl font-semibold">{@title}</h2>
          <p class="text-sm text-base-content/60">
            Status: {Map.get(@refresh_meta, :status, :ready)}
          </p>
        </div>
        <p :if={Map.get(@refresh_meta, :refreshed_at)} class="text-sm text-base-content/60">
          Updated {Calendar.strftime(@refresh_meta.refreshed_at, "%H:%M:%S")}
        </p>
      </div>

      <%= if @items == [] do %>
        <AshSDUI.Components.EmptyState.render title={@empty_title} body={@empty_body} />
      <% else %>
        <div class="space-y-3">
          <article
            :for={item <- @items}
            class="rounded-box border border-base-300 bg-base-100 p-4 shadow-sm"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="space-y-1">
                <h3 class="font-medium">{display_value(item, [:title, :name, :id])}</h3>
                <p :if={display_value(item, [:body, :detail, :description])} class="text-sm text-base-content/75">
                  {display_value(item, [:body, :detail, :description])}
                </p>
              </div>
              <span :if={display_value(item, [:status, :meta])} class="badge badge-outline">
                {display_value(item, [:status, :meta])}
              </span>
            </div>
          </article>
        </div>
      <% end %>
    </section>
    """
  end

  defp refresh_meta(nil, _binding_name), do: %{}

  defp refresh_meta(state, binding_name) do
    state.refresh
    |> Map.get(binding_name, %{})
  end

  defp display_value(item, keys) when is_map(item) do
    Enum.find_value(keys, fn key -> Map.get(item, key) || Map.get(item, to_string(key)) end)
  end

  defp display_value(item, _keys), do: item
end
