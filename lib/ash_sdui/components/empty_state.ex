defmodule AshSDUI.Components.EmptyState do
  @moduledoc """
  DaisyUI empty state used by generated collection views.
  """

  use Phoenix.Component

  attr(:title, :string, default: "No records")
  attr(:body, :string, default: nil)
  slot(:action)

  def render(assigns) do
    ~H"""
    <div class="hero min-h-64 bg-base-100 rounded-box border border-base-300">
      <div class="hero-content text-center">
        <div>
          <h2 class="text-2xl font-bold">{@title}</h2>
          <p :if={@body} class="text-base-content/60 my-4">{@body}</p>
          <%= for action <- @action do %>
            {render_slot(action)}
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
