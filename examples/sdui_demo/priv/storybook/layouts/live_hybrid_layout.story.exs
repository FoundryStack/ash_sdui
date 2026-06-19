defmodule SduiDemoWeb.Storybook.Layouts.LiveHybridLayout do
  use PhoenixStorybook.Story, :component

  alias AshSDUI.Layout.Builder
  alias AshSDUI.View
  alias PhoenixStorybook.Stories.Variation
  alias SduiDemo.UI.DemoLayouts

  def function, do: &AshSDUI.Components.SDUIRoot.render/1

  def variations do
    [
      %Variation{
        id: :runtime_hybrid,
        description:
          "Hybrid layout with generated resource nodes and runtime-bound generic components",
        attributes: %{
          tree: Builder.to_tree(DemoLayouts.hybrid_root(intents())),
          bindings: bindings(),
          state: state()
        }
      }
    ]
  end

  defp intents do
    [
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
  end

  defp bindings do
    %{
      metrics: [
        %{label: "Active sessions", value: 1820, hint: "Node binding: :metrics"},
        %{label: "Layout nodes", value: 6, hint: "Generated + runtime-aware components"},
        %{label: "Workflow state", value: "Live", hint: "State slice: :workflow"},
        %{label: "Refresh budget", value: "34 ms", hint: "Targeted updates"}
      ],
      feed: [
        %{
          title: "Initial collection snapshot",
          detail: "A node binds directly to a collection value from the runtime.",
          meta: "Story"
        }
      ],
      activity: [
        %{
          title: "Layout tree assigned",
          meta: "Mount",
          body: "The tree can be rendered in Storybook with the same runtime contract."
        }
      ]
    }
  end

  defp state do
    now = ~U[2026-06-17 12:00:00Z]

    %View.State{
      refresh: %{
        metrics: %{status: :ready, refreshed_at: now},
        feed: %{status: :ready, refreshed_at: now},
        activity: %{status: :ready, refreshed_at: now},
        last_refreshed_at: now
      },
      workflow: %{state: "review", updated_at: now}
    }
  end
end
