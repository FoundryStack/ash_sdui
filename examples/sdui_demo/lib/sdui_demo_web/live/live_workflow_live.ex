defmodule SduiDemoWeb.Live.LiveWorkflowLive do
  use SduiDemoWeb, :live_view

  alias AshSDUI.View

  @workflow_intents [
    %{
      name: :queue_review,
      label: "Queue Review",
      style: :secondary,
      target: {:workflow, :review}
    },
    %{
      name: :approve,
      label: "Approve",
      style: :primary,
      target: {:workflow, :approved},
      enabled_when: {:workflow, "review"}
    },
    %{name: :pause, label: "Pause", style: :info, target: {:workflow, :paused}}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Workflow State",
       intents: @workflow_intents,
       bindings: %{},
       state: %View.State{workflow: %{state: "draft", updated_at: DateTime.utc_now()}}
     )}
  end

  @impl true
  def handle_event("intent", %{"intent" => intent}, socket) do
    next_state =
      case intent do
        "queue_review" -> "review"
        "approve" -> "approved"
        "pause" -> "paused"
        _ -> socket.assigns.state.workflow.state
      end

    {:noreply,
     assign(socket, :state, %{
       socket.assigns.state
       | workflow: %{state: next_state, updated_at: DateTime.utc_now(), last_event: intent}
     })}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto flex w-full max-w-5xl flex-col gap-6 px-4 py-10">
      <header class="space-y-3">
        <p class="text-sm uppercase tracking-[0.2em] text-base-content/60">Workflow Runtime</p>
        <h1 class="text-4xl font-semibold">Workflow-driven surfaces</h1>
        <p class="max-w-3xl text-base-content/75">
          Workflow state becomes part of the generic runtime, which lets intents, badges, and content blocks react to staged transitions without a custom state machine per screen.
        </p>
      </header>

      <section class="rounded-box border border-base-300 bg-base-100 p-6">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <div class="space-y-3">
            <AshSDUI.Components.StatusBadge.render
              status={@state.workflow.state}
              variant={workflow_variant(@state.workflow.state)}
            />
            <p class="max-w-2xl text-sm text-base-content/75">
              Current workflow state updates intent availability. `Approve` only becomes active after the item enters `review`.
            </p>
          </div>

          <AshSDUI.Components.IntentBar.render
            ui={SduiDemo.UI.Resources.PostUI}
            intents={@intents}
            bindings={@bindings}
            state={@state}
          />
        </div>
      </section>

      <AshSDUI.Components.ActivityFeed.render items={[
        %{
          title: "Workflow state",
          meta: "Runtime",
          body: "Current value: #{@state.workflow.state}"
        },
        %{
          title: "Last update",
          meta: "Clock",
          body: Calendar.strftime(@state.workflow.updated_at, "%Y-%m-%d %H:%M:%S")
        }
      ]} />
    </main>
    """
  end

  defp workflow_variant("approved"), do: :success
  defp workflow_variant("review"), do: :warning
  defp workflow_variant("paused"), do: :info
  defp workflow_variant(_), do: :neutral
end
