defmodule SduiDemoWeb.Live.PersistedLayoutLive do
  use SduiDemoWeb, :live_view

  use AshSDUI,
    lookup: {:static, "demo-persisted-layout"},
    source: :stored,
    status: :published

  @impl true
  def mount(_params, _session, socket) do
    _ = SduiDemo.UI.DemoLayouts.publish_persisted_layout()
    layout_name = SduiDemo.UI.DemoLayouts.persisted_layout_name()

    {:ok,
     socket
     |> assign(:layout_name, layout_name)
     |> assign_tree(layout_name, source: :stored, status: :published)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl space-y-6">
      <header class="space-y-2">
        <p class="text-sm font-medium uppercase tracking-[0.18em] text-primary">Persisted Layout</p>
        <h1 class="text-3xl font-semibold text-base-content">
          Published layout loaded from AshSDUI.UINode
        </h1>
        <p class="max-w-3xl text-base-content/65">
          This page exercises AshSDUI.Layout.save/3, publish/2, and fetch/2 through the built-in ETS-backed AshSDUI.UINode storage path used for demos and tests.
        </p>
      </header>

      <section class="rounded-box border border-base-300 bg-base-100 p-6 shadow-sm">
        <dl class="grid gap-3 text-sm text-base-content/70 md:grid-cols-3">
          <div>
            <dt class="font-medium text-base-content">Layout name</dt>
            <dd>{@layout_name}</dd>
          </div>
          <div>
            <dt class="font-medium text-base-content">Storage</dt>
            <dd>AshSDUI.UINode</dd>
          </div>
          <div>
            <dt class="font-medium text-base-content">Source</dt>
            <dd>source: :stored, status: :published</dd>
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
