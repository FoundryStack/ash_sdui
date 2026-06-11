defmodule SduiDemoWeb.Components.CommentItem do
  use AshSDUI.Component,
    fragment: """
    fragment CommentItemData on Comment {
      id
      body
      postedAt
    }
    """

  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="comment-item bg-gray-50 rounded-lg p-3 border border-gray-200" data-testid="comment-item">
      <%= if @subject do %>
        <p class="text-gray-800 text-sm"><%= @subject.body %></p>
        <%= if @subject.posted_at do %>
          <p class="text-xs text-gray-400 mt-1">
            <%= Calendar.strftime(@subject.posted_at, "%b %d, %Y") %>
          </p>
        <% end %>
      <% else %>
        <p class="text-gray-400 text-sm italic">Comment unavailable</p>
      <% end %>
    </div>
    """
  end
end
