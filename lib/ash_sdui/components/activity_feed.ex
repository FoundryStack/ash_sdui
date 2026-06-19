defmodule AshSDUI.Components.ActivityFeed do
  @moduledoc """
  Generic feed/timeline renderer for append-only runtime data.
  """

  use Phoenix.Component

  AshSDUI.Registry.register("AshSDUI.ActivityFeed@v1", __MODULE__, %{
    fragment: "",
    subject_types: []
  })

  def __ash_sdui_component_name__, do: "AshSDUI.ActivityFeed@v1"
  def __ash_sdui_fragment__, do: ""
  def __ash_sdui_subject_types__, do: []

  attr(:items, :list, default: nil)
  attr(:bound_value, :any, default: nil)
  attr(:empty_title, :string, default: "No activity yet")
  attr(:class, :string, default: nil)

  def render(assigns) do
    assigns = assign(assigns, :items, assigns.items || List.wrap(assigns.bound_value))

    ~H"""
    <section class={["rounded-box border border-base-300 bg-base-100 p-5", @class]} data-testid="activity-feed">
      <%= if @items == [] do %>
        <AshSDUI.Components.EmptyState.render title={@empty_title} />
      <% else %>
        <div class="space-y-4">
          <article :for={item <- @items} class="border-b border-base-200 pb-4 last:border-b-0 last:pb-0">
            <div class="flex items-center justify-between gap-4">
              <h3 class="font-medium">{item.title}</h3>
              <span :if={Map.get(item, :meta)} class="text-xs uppercase tracking-[0.18em] text-base-content/50">
                {item.meta}
              </span>
            </div>
            <p :if={Map.get(item, :body)} class="mt-2 text-sm text-base-content/75">{item.body}</p>
          </article>
        </div>
      <% end %>
    </section>
    """
  end
end
