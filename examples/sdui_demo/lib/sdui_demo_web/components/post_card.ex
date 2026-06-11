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
    <article class="card bg-base-100 shadow border border-base-300" data-testid="post-card">
      <%= if @subject do %>
        <div class="card-body">
          <div class="flex items-start justify-between gap-3 mb-2">
            <h1 class="card-title text-2xl leading-snug flex-1"><%= @subject.title %></h1>
            <%= if @subject.published_at do %>
              <div class="badge badge-success shrink-0">Published</div>
            <% else %>
              <div class="badge badge-warning shrink-0">Draft</div>
            <% end %>
          </div>

          <%= if @subject.published_at do %>
            <p class="text-xs text-base-content/40 -mt-2 mb-4">
              <%= Calendar.strftime(@subject.published_at, "%B %d, %Y") %>
            </p>
          <% end %>

          <div class="prose max-w-none text-base-content/80">
            <p><%= @subject.body %></p>
          </div>

          <%= if map_size(@children) > 0 && @children[:author] do %>
            <div class="divider text-xs font-semibold text-base-content/40 uppercase tracking-widest">
              Author
            </div>
            <div class="author-region">
              <%= for child_rendered <- @children[:author] do %>
                <%= child_rendered %>
              <% end %>
            </div>
          <% end %>

          <%= if map_size(@children) > 0 && @children[:comments] do %>
            <div class="divider text-xs font-semibold text-base-content/40 uppercase tracking-widest">
              Comments (<%= length(@children[:comments]) %>)
            </div>
            <div class="comments-region space-y-3">
              <%= for child_rendered <- @children[:comments] do %>
                <%= child_rendered %>
              <% end %>
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="card-body items-center text-center py-12">
          <div class="text-4xl mb-3">📄</div>
          <p class="text-base-content/40">No post loaded</p>
        </div>
      <% end %>
    </article>
    """
  end
end
