defmodule SduiDemoWeb.Components.UserList do
  use AshSDUI.Component,
    fragment: """
    fragment UserListData on User {
      id
      username
      email
    }
    """

  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="space-y-2" data-testid="user-list">
      <div class="text-lg font-semibold text-gray-900">Users</div>
      <%= if @subject && is_list(@subject) do %>
        <%= for user <- @subject do %>
          <div class="flex items-center gap-3 p-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition">
            <div class="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
              <span class="text-sm font-bold text-blue-600">
                <%= String.first(user.username) |> String.upcase() %>
              </span>
            </div>
            <div class="flex-1">
              <div class="font-medium text-gray-900"><%= user.username %></div>
              <div class="text-sm text-gray-500"><%= user.email %></div>
            </div>
          </div>
        <% end %>
      <% else %>
        <p class="text-gray-500">No users available</p>
      <% end %>
    </div>
    """
  end
end
