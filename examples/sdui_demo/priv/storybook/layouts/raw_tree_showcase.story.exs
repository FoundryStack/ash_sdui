defmodule SduiDemoWeb.Storybook.Layouts.RawTreeShowcase do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &AshSDUI.Components.SDUIRoot.render/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Direct render-ready tree passed straight into SDUIRoot",
        attributes: %{
          tree: SduiDemo.UI.DemoLayouts.raw_tree()
        }
      }
    ]
  end
end
