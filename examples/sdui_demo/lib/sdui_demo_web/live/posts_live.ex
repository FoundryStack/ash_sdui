defmodule SduiDemoWeb.Live.PostsLive do
  use SduiDemoWeb, :live_view

  alias SduiDemo.Blog
  alias SduiDemo.Blog.Post

  @impl true
  def mount(_params, _session, socket) do
    posts = load_posts()
    {:ok, assign(socket, :posts, posts)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Ash.get(Post, id, domain: Blog) do
      {:ok, post} ->
        case Ash.destroy(post) do
          :ok ->
            {:noreply,
             socket
             |> put_flash(:info, "Post deleted.")
             |> assign(:posts, load_posts())}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not delete post.")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Post not found.")}
    end
  end

  defp load_posts do
    case Ash.read(Post, domain: Blog) do
      {:ok, posts} -> Enum.sort_by(posts, & &1.title)
      {:error, _} -> []
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-3xl font-bold">Blog Posts</h1>
          <p class="text-base-content/60 mt-1">All posts rendered via AshSDUI layouts</p>
        </div>
        <a href="/posts/new" class="btn btn-primary">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          New Post
        </a>
      </div>

      <%= if @posts == [] do %>
        <div class="hero min-h-64 bg-base-100 rounded-box border border-base-300">
          <div class="hero-content text-center">
            <div>
              <div class="text-6xl mb-4">📝</div>
              <h2 class="text-2xl font-bold">No posts yet</h2>
              <p class="text-base-content/60 my-4">Create your first post to see SDUI in action.</p>
              <a href="/posts/new" class="btn btn-primary">Create Post</a>
            </div>
          </div>
        </div>
      <% else %>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <%= for post <- @posts do %>
            <div class="card bg-base-100 shadow-md hover:shadow-lg transition-shadow border border-base-300">
              <div class="card-body">
                <div class="flex items-start justify-between gap-2">
                  <h2 class="card-title text-lg leading-snug flex-1"><%= post.title %></h2>
                  <%= if post.published_at do %>
                    <div class="badge badge-success badge-sm shrink-0">Published</div>
                  <% else %>
                    <div class="badge badge-warning badge-sm shrink-0">Draft</div>
                  <% end %>
                </div>
                <p class="text-base-content/70 text-sm line-clamp-3 mt-1">
                  <%= String.slice(post.body, 0, 200) %><%= if String.length(post.body) > 200, do: "…" %>
                </p>
                <%= if post.published_at do %>
                  <p class="text-xs text-base-content/40 mt-2">
                    <%= Calendar.strftime(post.published_at, "%b %d, %Y") %>
                  </p>
                <% end %>
                <div class="card-actions justify-end mt-4 gap-2">
                  <a href={"/posts/#{post.id}"} class="btn btn-sm btn-primary">Read</a>
                  <a href={"/posts/#{post.id}/edit"} class="btn btn-sm btn-ghost">Edit</a>
                  <button
                    phx-click="delete"
                    phx-value-id={post.id}
                    data-confirm="Delete this post?"
                    class="btn btn-sm btn-error btn-outline"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
