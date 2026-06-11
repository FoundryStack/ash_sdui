defmodule SduiDemoWeb.Components.PostCard do
  use AshSDUI.Component,
    fragment: """
    fragment PostCardData on Post {
      id
      title
      body
      publishedAt
    }
    """

  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <article class="post-card bg-white rounded-lg shadow-md overflow-hidden" data-testid="post-card">
      <%= if @subject do %>
        <div class="p-6">
          <div class="flex items-start justify-between mb-4">
            <h2 class="text-2xl font-bold text-gray-900 flex-1"><%= @subject.title %></h2>
            <%= if @subject.published_at do %>
              <span class="text-sm text-green-600 bg-green-50 px-2 py-1 rounded ml-4 shrink-0">
                Published
              </span>
            <% else %>
              <span class="text-sm text-yellow-600 bg-yellow-50 px-2 py-1 rounded ml-4 shrink-0">
                Draft
              </span>
            <% end %>
          </div>

          <p class="text-gray-700 leading-relaxed mb-6"><%= @subject.body %></p>

          <%= if map_size(@children) > 0 && @children[:author] do %>
            <div class="border-t border-gray-100 pt-4 mb-4">
              <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-3">Author</p>
              <div class="author-region">
                <%= for child_rendered <- @children[:author] do %>
                  <%= child_rendered %>
                <% end %>
              </div>
            </div>
          <% end %>

          <%= if map_size(@children) > 0 && @children[:comments] do %>
            <div class="border-t border-gray-100 pt-4">
              <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-3">
                Comments (<%= length(@children[:comments]) %>)
              </p>
              <div class="comments-region space-y-3">
                <%= for child_rendered <- @children[:comments] do %>
                  <%= child_rendered %>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="p-8 text-center">
          <p class="text-gray-500 text-lg">No post loaded</p>
        </div>
      <% end %>
    </article>
    """
  end
end
