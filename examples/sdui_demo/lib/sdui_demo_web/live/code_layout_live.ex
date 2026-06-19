defmodule SduiDemoWeb.Live.CodeLayoutLive do
  use SduiDemoWeb, :live_view
  use AshSDUI, lookup: {:static, "demo-code-layout"}

  @impl true
  def mount(_params, _session, socket) do
    SduiDemo.UI.DemoLayouts.register_code_layout()
    layout_name = SduiDemo.UI.DemoLayouts.code_layout_name()

    {:ok,
     socket
     |> assign(:layout_name, layout_name)
     |> assign_tree(layout_name, source: :registered)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl space-y-6">
      <header class="space-y-2">
        <p class="text-sm font-medium uppercase tracking-[0.18em] text-primary">Code Layout</p>
        <h1 class="text-3xl font-semibold text-base-content">Registered layout via AshSDUI.Layout</h1>
        <p class="max-w-3xl text-base-content/65">
          This page registers a named layout in code, resolves it by name, and renders it through the standard `use AshSDUI` lookup path.
        </p>
      </header>

      <section class="rounded-box border border-base-300 bg-base-100 p-6 shadow-sm">
        <dl class="grid gap-3 text-sm text-base-content/70 md:grid-cols-3">
          <div>
            <dt class="font-medium text-base-content">Layout name</dt>
            <dd>{@layout_name}</dd>
          </div>
          <div>
            <dt class="font-medium text-base-content">Lookup</dt>
            <dd>use AshSDUI with a static layout lookup</dd>
          </div>
          <div>
            <dt class="font-medium text-base-content">Authoring</dt>
            <dd>AshSDUI.Layout.Builder.resource/2 plus AshSDUI.Layout.register/2</dd>
          </div>
        </dl>
      </section>

      <.sdui_root tree={@__sdui_tree__} />
    </div>
    """
  end

  defp assign_tree(socket, layout_name, opts) do
    case AshSDUI.Renderer.to_tree(layout_name, opts) do
      {:ok, tree} -> assign(socket, :__sdui_tree__, tree)
      {:error, _reason} -> assign(socket, :__sdui_tree__, nil)
    end
  end
end
