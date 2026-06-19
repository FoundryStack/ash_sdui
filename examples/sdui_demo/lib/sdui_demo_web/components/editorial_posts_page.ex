defmodule SduiDemoWeb.Components.EditorialPostsPage do
  use AshSDUI.Component,
    fragment: """
    fragment EditorialPostsPageData on Layout {
      id
    }
    """

  use Phoenix.Component

  def render(assigns) do
    props = assigns.props || %{}

    assigns =
      assigns
      |> assign(:title, Map.get(props, :title, "AshSDUI Journal"))
      |> assign(:subtitle, Map.get(props, :subtitle))
      |> assign(:create_label, Map.get(props, :create_label, "Create Post"))
      |> assign(:empty_title, Map.get(props, :empty_title, "No posts yet"))
      |> assign(
        :empty_body,
        Map.get(
          props,
          :empty_body,
          "Create your first entry to see the editorial recipe in action."
        )
      )
      |> assign(:featured, Map.get(props, :featured))
      |> assign(:posts, Map.get(props, :posts, []))

    ~H"""
    <section class="space-y-10" data-testid="editorial-posts-page">
      <header class="space-y-4 border-b border-base-300 pb-8">
        <div class="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div class="max-w-3xl space-y-3">
            <p class="text-sm font-medium uppercase tracking-[0.2em] text-primary">
              AshSDUI Demo Blog
            </p>
            <h1 class="text-4xl font-semibold leading-tight text-base-content lg:text-5xl">
              {@title}
            </h1>
            <p class="text-base leading-7 text-base-content/70 lg:text-lg">
              {@subtitle}
            </p>
          </div>
          <div class="flex flex-wrap gap-3">
            <a href="/posts/new" class="btn btn-primary">{@create_label}</a>
            <a href="/storybook" class="btn btn-outline">Storybook</a>
          </div>
        </div>
      </header>

      <div class="grid gap-10 lg:grid-cols-[minmax(0,1fr)_18rem] lg:items-start">
        <div class="space-y-8" data-testid="editorial-feed">
          <%= if @featured do %>
            <section class="space-y-4 border-b border-base-300 pb-8">
              <div class="flex items-center justify-between gap-4">
                <h2 class="text-2xl font-semibold text-base-content">Featured story</h2>
                <span class="badge badge-primary badge-outline">Recipe-driven</span>
              </div>
              <article class="space-y-4">
                <div class="flex flex-wrap items-center gap-3 text-sm text-base-content/60">
                  <span class={status_badge_class(@featured.status)}>{@featured.status}</span>
                  <span :if={@featured.author_name}>{@featured.author_name}</span>
                  <span :if={@featured.published_at}>{format_date(@featured.published_at)}</span>
                </div>
                <div class="space-y-3">
                  <h3 class="text-4xl font-semibold leading-tight text-base-content">
                    <a href={@featured.read_path} class="hover:text-primary">{@featured.title}</a>
                  </h3>
                  <p class="max-w-3xl text-base leading-8 text-base-content/75">
                    {@featured.excerpt}
                  </p>
                </div>
                <div class="flex flex-wrap gap-2">
                  <a href={@featured.read_path} class="btn btn-primary btn-sm">Read</a>
                  <a href={@featured.edit_path} class="btn btn-ghost btn-sm">Edit</a>
                </div>
              </article>
            </section>
          <% end %>

          <section class="space-y-5">
            <div class="flex items-center justify-between gap-4">
              <h2 class="text-2xl font-semibold text-base-content">More from the feed</h2>
              <span class="text-sm text-base-content/60">
                {length(@posts) + if(@featured, do: 1, else: 0)} stories
              </span>
            </div>

            <%= if Enum.empty?(@posts) and is_nil(@featured) do %>
              <div class="rounded-box border border-dashed border-base-300 bg-base-100 px-8 py-16 text-center">
                <h3 class="text-xl font-semibold text-base-content">{@empty_title}</h3>
                <p class="mt-2 text-base-content/65">
                  {@empty_body}
                </p>
                <div class="mt-6">
                  <a href="/posts/new" class="btn btn-primary">{@create_label}</a>
                </div>
              </div>
            <% else %>
              <div class="divide-y divide-base-300 border-y border-base-300">
                <%= for post <- @posts do %>
                  <article class="space-y-4 py-6">
                    <div class="flex flex-wrap items-center gap-3 text-sm text-base-content/60">
                      <span class={status_badge_class(post.status)}>{post.status}</span>
                      <span :if={post.author_name}>{post.author_name}</span>
                      <span :if={post.published_at}>{format_date(post.published_at)}</span>
                    </div>
                    <div class="space-y-3">
                      <h3 class="text-3xl font-semibold leading-tight text-base-content">
                        <a href={post.read_path} class="hover:text-primary">{post.title}</a>
                      </h3>
                      <p class="max-w-3xl text-base leading-8 text-base-content/72">
                        {post.excerpt}
                      </p>
                    </div>
                    <div class="flex flex-wrap gap-2">
                      <a href={post.read_path} class="btn btn-primary btn-sm">Read</a>
                      <a href={post.edit_path} class="btn btn-ghost btn-sm">Edit</a>
                      <button
                        type="button"
                        phx-click="delete"
                        phx-value-id={post.id}
                        data-confirm="Delete this post?"
                        class="btn btn-error btn-outline btn-sm"
                      >
                        Delete
                      </button>
                    </div>
                  </article>
                <% end %>
              </div>
            <% end %>
          </section>
        </div>

        <aside class="space-y-4">
          <section class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm font-medium uppercase tracking-[0.18em] text-base-content/55">
              Why this feels different
            </p>
            <p class="mt-3 text-sm leading-6 text-base-content/70">
              The data loading and actions still come from `AshSDUI.LiveResource`, but the shape of the page is owned by an app recipe and component pair.
            </p>
          </section>

          <section class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm font-medium uppercase tracking-[0.18em] text-base-content/55">
              Recipe stack
            </p>
            <ul class="mt-3 space-y-3 text-sm text-base-content/72">
              <li><span class="font-medium text-base-content">Screen:</span> `PostUI.index`</li>
              <li><span class="font-medium text-base-content">Recipe:</span> `:editorial_blog`</li>
              <li>
                <span class="font-medium text-base-content">Renderer:</span> `EditorialPostsPage@v1`
              </li>
            </ul>
          </section>

          <section class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm font-medium uppercase tracking-[0.18em] text-base-content/55">
              Quick links
            </p>
            <div class="mt-4 flex flex-col gap-2">
              <a href="/posts/new" class="btn btn-primary btn-sm">Write a post</a>
              <a href="/posts/generated" class="btn btn-outline btn-sm">Open generated index</a>
              <a href="/storybook/components/editorial_posts_page" class="btn btn-outline btn-sm">
                Open this in Storybook
              </a>
            </div>
          </section>
        </aside>
      </div>
    </section>
    """
  end

  defp format_date(nil), do: nil
  defp format_date(date), do: Calendar.strftime(date, "%B %d, %Y")

  defp status_badge_class("Published"), do: "badge badge-success badge-outline"
  defp status_badge_class(_), do: "badge badge-warning badge-outline"
end
