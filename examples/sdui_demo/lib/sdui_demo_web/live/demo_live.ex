defmodule SduiDemoWeb.Live.DemoLive do
  use SduiDemoWeb, :live_view

  @layouts [
    {"user-dashboard", "User Dashboard"},
    {"blog-post", "Blog Post (multi-resource)"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, tree} = AshSDUI.Renderer.to_tree("user-dashboard")

    {:ok,
     socket
     |> assign(:__sdui_tree__, tree)
     |> assign(:current_layout, "user-dashboard")
     |> assign(:layouts, @layouts)}
  end

  @impl true
  def handle_event("switch_layout", %{"name" => name}, socket) do
    case AshSDUI.Renderer.to_tree(name) do
      {:ok, tree} ->
        {:noreply,
         socket
         |> assign(:__sdui_tree__, tree)
         |> assign(:current_layout, name)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Layout '#{name}' not found")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="demo-page max-w-6xl mx-auto px-4 py-8">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-3xl font-bold text-gray-900">Ash SDUI Demo</h1>
        <div class="flex gap-2">
          <%= for {name, label} <- @layouts do %>
            <button
              phx-click="switch_layout"
              phx-value-name={name}
              class={"px-4 py-2 rounded-lg text-sm font-medium transition " <>
                if(@current_layout == name,
                  do: "bg-blue-600 text-white",
                  else: "bg-gray-100 text-gray-700 hover:bg-gray-200")}
            >
              <%= label %>
            </button>
          <% end %>
        </div>
      </div>

      <div class="mb-4 text-sm text-gray-500">
        Layout: <code class="bg-gray-100 px-2 py-0.5 rounded"><%= @current_layout %></code>
      </div>

      <.sdui_root tree={@__sdui_tree__} />
    </div>
    """
  end

  defp sdui_root(assigns) do
    AshSDUI.Components.SDUIRoot.render(assigns)
  end
end
