defmodule SduiDemoWeb.Storybook.Components.StreamList do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &AshSDUI.Components.StreamList.render/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Generic live collection list for append merge remove updates",
        attributes: %{
          title: "Stream List",
          binding_name: :collection,
          records: [
            %{
              id: "feed-1",
              title: "First item",
              body: "Initial collection snapshot",
              status: "seed"
            },
            %{id: "feed-2", title: "Second item", body: "Live update target", status: "append"}
          ],
          state: %AshSDUI.View.State{
            refresh: %{collection: %{status: :ready, refreshed_at: ~U[2026-06-17 12:00:00Z]}}
          }
        }
      }
    ]
  end
end
