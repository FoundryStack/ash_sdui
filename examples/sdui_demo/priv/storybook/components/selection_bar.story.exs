defmodule SduiDemoWeb.Storybook.Components.SelectionBar do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &AshSDUI.Components.SelectionBar.render/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Selection summary with embedded actions",
        attributes: %{
          count: 3,
          label: "items selected"
        }
      }
    ]
  end
end
