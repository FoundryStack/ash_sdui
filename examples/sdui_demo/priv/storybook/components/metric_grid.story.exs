defmodule SduiDemoWeb.Storybook.Components.MetricGrid do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &AshSDUI.Components.MetricGrid.render/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Generic metric cards for refreshable runtime dashboards",
        attributes: %{
          metrics: [
            %{label: "Active sessions", value: 1642, hint: "Refresh-aware binding"},
            %{label: "Queued actions", value: 8, hint: "Intent execution"},
            %{label: "Visible cards", value: 31, hint: "Partial UI updates"},
            %{label: "Latency budget", value: "52 ms", hint: "Runtime metadata"}
          ]
        }
      }
    ]
  end
end
