defmodule SduiDemoWeb.Components.UserCard do
  use AshSDUI.Component,
    fragment: """
    fragment UserCardData on User {
      id
      username
      email
      avatarUrl
    }
    """

  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow border border-base-300" data-testid="user-card">
      <%= if @subject do %>
        <div class="card-body p-4">
          <div class="flex items-center gap-4">
            <div class="avatar placeholder">
              <div class="bg-primary text-primary-content rounded-full w-12">
                <%= if @subject.avatar_url do %>
                  <img src={@subject.avatar_url} alt={@subject.username} class="rounded-full" />
                <% else %>
                  <span class="text-lg font-bold">
                    {String.first(@subject.username) |> String.upcase()}
                  </span>
                <% end %>
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <p class="font-semibold text-base truncate">{@subject.username}</p>
              <%= if @subject.email do %>
                <p class="text-sm text-base-content/60 truncate">{@subject.email}</p>
              <% end %>
            </div>
            <div class="badge badge-primary badge-outline badge-sm">
              {Map.get(@props, "role", "Author")}
            </div>
          </div>
        </div>
      <% else %>
        <div class="card-body p-4 text-center">
          <p class="text-base-content/40 text-sm">No author loaded</p>
        </div>
      <% end %>
    </div>
    """
  end
end
