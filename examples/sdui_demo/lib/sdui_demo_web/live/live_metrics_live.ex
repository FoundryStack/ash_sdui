defmodule SduiDemoWeb.Live.LiveMetricsLive do
  use SduiDemoWeb, :live_view

  alias AshSDUI.View

  @refresh_intents [
    %{
      name: :refresh_metrics,
      label: "Refresh Metrics",
      style: :primary,
      target: {:refresh, :metrics}
    },
    %{
      name: :append_activity,
      label: "Append Activity",
      style: :secondary,
      target: {:event, "append_activity"}
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Live Metrics")
     |> assign(:intents, @refresh_intents)
     |> assign(:bindings, %{})
     |> assign(:state, %View.State{refresh: %{last_refreshed_at: DateTime.utc_now()}})
     |> assign_runtime()}
  end

  @impl true
  def handle_event("intent", %{"intent" => "refresh_metrics"}, socket) do
    {:noreply,
     socket
     |> assign_runtime()
     |> update(:state, fn state ->
       %{state | refresh: Map.put(state.refresh || %{}, :last_refreshed_at, DateTime.utc_now())}
     end)}
  end

  def handle_event("append_activity", _params, socket) do
    event = %{
      title: "Refresh tick",
      meta: "Runtime event",
      body: "A generic event updated the feed without changing the view contract."
    }

    {:noreply, update(socket, :feed, &[event | &1])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto flex w-full max-w-6xl flex-col gap-6 px-4 py-10">
      <header class="space-y-3">
        <p class="text-sm uppercase tracking-[0.2em] text-base-content/60">Live Bindings</p>
        <h1 class="text-4xl font-semibold">Refreshable runtime panels</h1>
        <p class="max-w-3xl text-base-content/75">
          This route demonstrates generic refresh state, command-style intents, and live-aware reusable components without dropping into a domain-specific UI.
        </p>
      </header>

      <AshSDUI.Components.IntentBar.render
        ui={SduiDemo.UI.Resources.PostUI}
        intents={@intents}
        bindings={@bindings}
        state={@state}
      />

      <AshSDUI.Components.MetricGrid.render metrics={@metrics} />

      <div class="flex items-center gap-3 text-sm text-base-content/65">
        <span>Last refreshed:</span>
        <span>{Calendar.strftime(@state.refresh.last_refreshed_at, "%H:%M:%S")}</span>
      </div>

      <AshSDUI.Components.ActivityFeed.render items={@feed} />
    </main>
    """
  end

  defp assign_runtime(socket) do
    assign(socket,
      metrics: [
        %{label: "Active sessions", value: Enum.random(1200..1800), hint: "PubSub-ready binding"},
        %{label: "Visible cards", value: Enum.random(24..40), hint: "Partial node refresh"},
        %{label: "Queued actions", value: Enum.random(3..12), hint: "Intent execution surface"},
        %{
          label: "Latency budget",
          value: "#{Enum.random(40..95)} ms",
          hint: "Live runtime envelope"
        }
      ],
      feed: [
        %{
          title: "Bindings loaded",
          meta: "Mount",
          body: "The route mounted with refresh-aware runtime state."
        },
        %{
          title: "Intent bar ready",
          meta: "UI",
          body: "Toolbar actions are declarative and can drive refreshes or custom events."
        }
      ]
    )
  end
end
