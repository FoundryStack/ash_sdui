defmodule SduiDemoWeb.Live.LayoutAdminLive do
  use SduiDemoWeb, :live_view

  alias SduiDemo.UI.DemoLayouts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign_snapshot(socket)}
  end

  @impl true
  def handle_event("register_code_layout", _params, socket) do
    DemoLayouts.register_code_layout()

    {:noreply,
     socket
     |> assign_snapshot()
     |> put_flash(:info, "Registered the code layout.")}
  end

  def handle_event("save_persisted_layout", _params, socket) do
    case DemoLayouts.save_persisted_layout() do
      {:ok, _records} ->
        {:noreply,
         socket
         |> assign_snapshot()
         |> put_flash(:info, "Saved the persisted layout as a draft.")}

      {:error, reason} ->
        {:noreply,
         put_flash(socket, :error, "Could not save persisted layout: #{inspect(reason)}")}
    end
  end

  def handle_event("publish_persisted_layout", _params, socket) do
    case DemoLayouts.publish_persisted_layout() do
      {:ok, _records} ->
        {:noreply,
         socket
         |> assign_snapshot()
         |> put_flash(:info, "Published the persisted layout.")}

      {:error, reason} ->
        {:noreply,
         put_flash(socket, :error, "Could not publish persisted layout: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl space-y-6">
      <header class="space-y-2">
        <p class="text-sm font-medium uppercase tracking-[0.18em] text-primary">Layout API Tour</p>
        <h1 class="text-3xl font-semibold text-base-content">
          Manage code and persisted demo layouts
        </h1>
        <p class="max-w-3xl text-base-content/65">
          This page is the admin-style companion to the raw, code, and persisted layout showcases. It exercises the public AshSDUI.Layout API directly.
        </p>
      </header>

      <div class="grid gap-4 lg:grid-cols-2">
        <section class="rounded-box border border-base-300 bg-base-100 p-6 shadow-sm">
          <div class="space-y-4">
            <div>
              <h2 class="text-xl font-semibold text-base-content">Code layout</h2>
              <p class="mt-1 text-sm text-base-content/65">
                Register a named layout and open the route that resolves it by name.
              </p>
            </div>

            <dl class="space-y-2 text-sm text-base-content/72">
              <div class="flex justify-between gap-4">
                <dt class="font-medium text-base-content">Registered?</dt>
                <dd>{yes_no(@snapshot.code_registered?)}</dd>
              </div>
              <div class="flex justify-between gap-4">
                <dt class="font-medium text-base-content">Root component</dt>
                <dd>{@snapshot.code_component || "Not registered"}</dd>
              </div>
            </dl>

            <div class="flex flex-wrap gap-3">
              <button phx-click="register_code_layout" class="btn btn-primary btn-sm">
                Register code layout
              </button>
              <a href="/layouts/code" class="btn btn-outline btn-sm">Open code layout route</a>
            </div>
          </div>
        </section>

        <section class="rounded-box border border-base-300 bg-base-100 p-6 shadow-sm">
          <div class="space-y-4">
            <div>
              <h2 class="text-xl font-semibold text-base-content">Persisted layout</h2>
              <p class="mt-1 text-sm text-base-content/65">
                Save a draft layout into AshSDUI.UINode, then publish it and open the stored-layout route.
              </p>
            </div>

            <dl class="space-y-2 text-sm text-base-content/72">
              <div class="flex justify-between gap-4">
                <dt class="font-medium text-base-content">Stored?</dt>
                <dd>{yes_no(@snapshot.persisted_available?)}</dd>
              </div>
              <div class="flex justify-between gap-4">
                <dt class="font-medium text-base-content">Root component</dt>
                <dd>{@snapshot.persisted_component || "Not stored"}</dd>
              </div>
              <div class="flex justify-between gap-4">
                <dt class="font-medium text-base-content">Statuses</dt>
                <dd>
                  {Enum.join(Enum.map(@snapshot.persisted_statuses, &to_string/1), ", ")
                  |> blank_fallback("None")}
                </dd>
              </div>
              <div class="flex justify-between gap-4">
                <dt class="font-medium text-base-content">Node count</dt>
                <dd>{@snapshot.persisted_node_count}</dd>
              </div>
            </dl>

            <div class="flex flex-wrap gap-3">
              <button phx-click="save_persisted_layout" class="btn btn-primary btn-sm">
                Save draft
              </button>
              <button phx-click="publish_persisted_layout" class="btn btn-success btn-sm">
                Publish
              </button>
              <a href="/layouts/persisted" class="btn btn-outline btn-sm">Open persisted route</a>
            </div>
          </div>
        </section>
      </div>

      <section class="rounded-box border border-base-300 bg-base-100 p-6 shadow-sm">
        <div class="flex flex-wrap gap-3">
          <a href="/layouts/raw-tree" class="btn btn-ghost btn-sm">Open raw tree route</a>
          <a href="/storybook/layouts/raw_tree_showcase" class="btn btn-ghost btn-sm">
            Open raw tree story
          </a>
          <a href="/storybook/layouts/persisted_layout_showcase" class="btn btn-ghost btn-sm">
            Open persisted layout story
          </a>
        </div>
      </section>
    </div>
    """
  end

  defp assign_snapshot(socket) do
    assign(socket, :snapshot, DemoLayouts.status_snapshot())
  end

  defp yes_no(true), do: "Yes"
  defp yes_no(false), do: "No"

  defp blank_fallback("", fallback), do: fallback
  defp blank_fallback(value, _fallback), do: value
end
