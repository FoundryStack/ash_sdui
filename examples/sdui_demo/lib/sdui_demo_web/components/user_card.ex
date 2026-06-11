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
    <div class="card shadow-lg rounded-lg overflow-hidden bg-white" data-testid="user-card">
      <%= if @subject do %>
        <div class="bg-gradient-to-r from-blue-500 to-blue-600 h-32"></div>
        <div class="px-6 pb-6">
          <div class="flex justify-between items-start -mt-16 relative z-10">
            <div>
              <%= if @subject.avatar_url do %>
                <img
                  src={@subject.avatar_url}
                  alt={@subject.username}
                  class="w-24 h-24 rounded-full border-4 border-white shadow-md"
                />
              <% else %>
                <div class="w-24 h-24 rounded-full border-4 border-white bg-gray-200 flex items-center justify-center">
                  <span class="text-2xl font-bold text-gray-500">
                    <%= String.first(@subject.username) |> String.upcase() %>
                  </span>
                </div>
              <% end %>
            </div>
            <div class="flex gap-2 mt-2">
              <%= if @children[:actions] do %>
                <%= render_slot(@children[:actions]) %>
              <% end %>
            </div>
          </div>
          <div class="mt-4">
            <h2 class="text-2xl font-bold text-gray-900"><%= @subject.username %></h2>
            <p class="text-gray-600 mt-1"><%= @subject.email %></p>
          </div>
          <div class="mt-4 pt-4 border-t border-gray-200">
            <div class="text-sm text-gray-500">
              <p>User ID: <code class="bg-gray-100 px-2 py-1 rounded text-xs"><%= @subject.id %></code></p>
            </div>
          </div>
        </div>
      <% else %>
        <div class="p-8 text-center">
          <p class="text-gray-500 text-lg">No user loaded</p>
        </div>
      <% end %>
    </div>
    """
  end
end
