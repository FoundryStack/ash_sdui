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
    <div class="chat chat-start" data-testid="comment-item">
      <%= if @subject do %>
        <div class="chat-bubble">
          <p class="text-sm"><%= @subject.body %></p>
        </div>
        <%= if @subject.posted_at do %>
          <div class="chat-footer text-xs text-base-content/40 mt-1">
            <%= Calendar.strftime(@subject.posted_at, "%b %d, %Y at %H:%M") %>
          </div>
        <% end %>
      <% else %>
        <div class="chat-bubble chat-bubble-ghost">
          <p class="text-xs italic text-base-content/40">Comment unavailable</p>
        </div>
      <% end %>
    </div>
    """
  end
end
