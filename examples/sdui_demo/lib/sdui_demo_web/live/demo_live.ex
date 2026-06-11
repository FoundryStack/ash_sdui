defmodule SduiDemoWeb.Live.DemoLive do
  use SduiDemoWeb, :live_view

  @features [
    %{
      icon: "🌲",
      title: "Tree-based layout",
      desc: "Compose any UI from a JSON tree of nodes. Each node declares its component, region, and Ash subject."
    },
    %{
      icon: "🔌",
      title: "Multi-resource nesting",
      desc: "A PostCard embeds a UserCard (author) and CommentItems — all resolved independently from separate Ash resources."
    },
    %{
      icon: "🌍",
      title: "i18n via gettext",
      desc: "Use label_key instead of hardcoded strings. Labels resolve at runtime from .po files with full gettext support."
    },
    %{
      icon: "📖",
      title: "Storybook integration",
      desc: "Every SDUI component auto-registers a storybook story. Browse components in isolation."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :features, @features)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="hero min-h-64 bg-gradient-to-br from-primary/10 to-secondary/10 rounded-box mb-12">
        <div class="hero-content text-center max-w-2xl">
          <div>
            <div class="text-5xl mb-4">⚡</div>
            <h1 class="text-4xl font-bold mb-3">AshSDUI Demo</h1>
            <p class="text-lg text-base-content/70 mb-6">
              Server-driven UI for Phoenix LiveView, powered by Ash resources.
              Change layouts without redeployment — the server owns the component tree.
            </p>
            <div class="flex flex-wrap gap-3 justify-center">
              <a href="/posts" class="btn btn-primary btn-lg">
                Browse Blog Posts
              </a>
              <a href="/posts/new" class="btn btn-outline btn-lg">
                Create a Post
              </a>
              <a href="/storybook" class="btn btn-ghost btn-lg">
                View Storybook
              </a>
            </div>
          </div>
        </div>
      </div>

      <h2 class="text-2xl font-bold mb-6 text-center">Key Features</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-12">
        <%= for feature <- @features do %>
          <div class="card bg-base-100 border border-base-300 shadow-sm">
            <div class="card-body p-5">
              <div class="flex items-start gap-4">
                <div class="text-3xl"><%= feature.icon %></div>
                <div>
                  <h3 class="font-semibold text-base mb-1"><%= feature.title %></h3>
                  <p class="text-sm text-base-content/60"><%= feature.desc %></p>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <div class="card bg-base-200 border border-base-300">
        <div class="card-body p-6">
          <h3 class="font-bold text-lg mb-3">How it works</h3>
          <ol class="steps steps-vertical text-sm">
            <li class="step step-primary">
              Ash Resource is annotated with <code class="badge badge-ghost badge-sm">use AshSDUI.Resource</code> or a standalone UI module
            </li>
            <li class="step step-primary">
              A Layout Definition tree is registered: nodes declare component, region, and subject resource+id
            </li>
            <li class="step step-primary">
              At render time, <code class="badge badge-ghost badge-sm">AshSDUI.Renderer.to_tree/1</code> resolves each node's subject from Ash
            </li>
            <li class="step step-primary">
              <code class="badge badge-ghost badge-sm">&lt;.sdui_root tree={@tree} /&gt;</code> recursively renders the tree via registered Phoenix components
            </li>
          </ol>
        </div>
      </div>
    </div>
    """
  end
end
