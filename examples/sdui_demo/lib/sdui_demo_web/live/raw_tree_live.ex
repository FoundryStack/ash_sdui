defmodule SduiDemoWeb.Live.RawTreeLive do
  use SduiDemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :tree, SduiDemo.UI.DemoLayouts.raw_tree())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl space-y-6">
      <header class="space-y-2">
        <p class="text-sm font-medium uppercase tracking-[0.18em] text-primary">Raw Tree Showcase</p>
        <h1 class="text-3xl font-semibold text-base-content">Direct SDUIRoot rendering</h1>
        <p class="max-w-3xl text-base-content/65">
          This page skips LiveResource and AshSDUI.Layout.register/2. It builds a render-ready tree in memory and passes it straight into AshSDUI.Components.SDUIRoot.
        </p>
      </header>

      <section class="rounded-box border border-base-300 bg-base-100 p-6 shadow-sm">
        <dl class="grid gap-3 text-sm text-base-content/70 md:grid-cols-3">
          <div>
            <dt class="font-medium text-base-content">API</dt>
            <dd>AshSDUI.Layout.Builder.to_tree/1</dd>
          </div>
          <div>
            <dt class="font-medium text-base-content">Renderer</dt>
            <dd>AshSDUI.Components.SDUIRoot</dd>
          </div>
          <div>
            <dt class="font-medium text-base-content">Use case</dt>
            <dd>Minimal custom pages and direct component graph experiments</dd>
          </div>
        </dl>
      </section>

      <.sdui_root tree={@tree} />
    </div>
    """
  end

  defp sdui_root(assigns) do
    AshSDUI.Components.SDUIRoot.render(assigns)
  end
end
