defmodule SduiDemoWeb.Live.LiveHybridLive do
  use SduiDemoWeb, :live_view

  alias AshSDUI.LiveScreen
  alias AshSDUI.View
  alias SduiDemo.UI.DemoLayouts

  @hybrid_intents [
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
    },
    %{
      name: :queue_review,
      label: "Queue Review",
      style: :secondary,
      target: {:workflow, :review}
    },
    %{
      name: :approve,
      label: "Approve",
      style: :info,
      target: {:workflow, :approved},
      enabled_when: {:workflow, "review"}
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    now = DateTime.utc_now()

    socket =
      socket
      |> assign(:page_title, "Hybrid Layout Runtime")
      |> assign(:bindings, initial_bindings())
      |> assign(
        :state,
        %View.State{
          refresh: %{
            metrics: %{status: :ready, refreshed_at: now},
            feed: %{status: :ready, refreshed_at: now},
            activity: %{status: :ready, refreshed_at: now},
            last_refreshed_at: now
          },
          workflow: %{state: "draft", updated_at: now}
        }
      )
      |> LiveScreen.assign_layout(
        DemoLayouts.hybrid_layout_name(),
        DemoLayouts.hybrid_root(@hybrid_intents)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("intent", %{"intent" => "refresh_metrics"}, socket) do
    {:noreply,
     socket
     |> assign(:bindings, Map.put(socket.assigns.bindings, :metrics, refreshed_metrics()))
     |> update(:bindings, fn bindings ->
       update_in(bindings.activity, fn items ->
         [
           %{
             title: "Metrics refreshed",
             meta: "Intent",
             body: "A node-scoped binding refreshed without changing the rest of the layout tree."
           }
           | items
         ]
       end)
     end)
     |> mark_binding(:metrics)
     |> mark_binding(:activity)}
  end

  def handle_event("intent", %{"intent" => "queue_review"}, socket) do
    {:noreply, transition_workflow(socket, "review", "Queued for review")}
  end

  def handle_event("intent", %{"intent" => "approve"}, socket) do
    next_state =
      if socket.assigns.state.workflow.state == "review" do
        "approved"
      else
        socket.assigns.state.workflow.state
      end

    {:noreply, transition_workflow(socket, next_state, "Workflow approved")}
  end

  def handle_event("append_activity", _params, socket) do
    feed_item = %{
      title: "Hybrid event",
      detail: "A layout-bound collection node updated through the runtime contract.",
      meta: "Append"
    }

    activity_item = %{
      title: "Activity appended",
      meta: "Event",
      body: "The layout reused the same bindings/state contract across multiple component types."
    }

    {:noreply,
     socket
     |> assign(:bindings, %{
       socket.assigns.bindings
       | feed: [feed_item | socket.assigns.bindings.feed],
         activity: [activity_item | socket.assigns.bindings.activity]
     })
     |> mark_binding(:feed)
     |> mark_binding(:activity)}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto flex w-full max-w-6xl flex-col gap-6 px-4 py-10">
      <header class="space-y-3">
        <p class="text-sm uppercase tracking-[0.2em] text-base-content/60">Hybrid Layouts</p>
        <h1 class="text-4xl font-semibold">Generated resources inside a live runtime tree</h1>
        <p class="max-w-4xl text-base-content/75">
          This route mixes a generated resource node with generic runtime-bound components in one SDUI tree. Layout nodes stay serializable, while bindings and workflow state remain live runtime data owned by the LiveView.
        </p>
      </header>

      <AshSDUI.Components.SDUIRoot.render
        tree={@__sdui_tree__}
        bindings={@bindings}
        state={@state}
        context={%{surface: :hybrid_demo}}
      />
    </main>
    """
  end

  defp initial_bindings do
    %{
      metrics: refreshed_metrics(),
      feed: [
        %{
          title: "Initial collection snapshot",
          detail: "A node binds directly to a collection value from the runtime.",
          meta: "Mount"
        }
      ],
      activity: [
        %{
          title: "Layout tree assigned",
          meta: "Mount",
          body:
            "The hybrid route uses AshSDUI.LiveScreen to register and render an ephemeral layout."
        },
        %{
          title: "Runtime contract active",
          meta: "Bindings",
          body: "Components receive bindings, state, and node metadata through SDUIRoot."
        }
      ]
    }
  end

  defp refreshed_metrics do
    [
      %{label: "Active sessions", value: Enum.random(1500..2300), hint: "Node binding: :metrics"},
      %{label: "Layout nodes", value: 6, hint: "Generated + runtime-aware components"},
      %{label: "Workflow state", value: "Live", hint: "State slice: :workflow"},
      %{label: "Refresh budget", value: "#{Enum.random(20..65)} ms", hint: "Targeted updates"}
    ]
  end

  defp transition_workflow(socket, state, title) do
    now = DateTime.utc_now()

    socket
    |> assign(:state, %{
      socket.assigns.state
      | workflow: %{state: state, updated_at: now},
        refresh: Map.put(socket.assigns.state.refresh || %{}, :last_refreshed_at, now)
    })
    |> update(:bindings, fn bindings ->
      update_in(bindings.activity, fn items ->
        [
          %{
            title: title,
            meta: "Workflow",
            body: "A node bound to the workflow slice updated without custom component glue."
          }
          | items
        ]
      end)
    end)
    |> mark_binding(:activity)
  end

  defp mark_binding(socket, binding_name) do
    now = DateTime.utc_now()

    update(socket, :state, fn state ->
      refresh =
        state.refresh
        |> Map.put(binding_name, %{status: :ready, refreshed_at: now})
        |> Map.put(:last_refreshed_at, now)

      %{state | refresh: refresh}
    end)
  end
end
