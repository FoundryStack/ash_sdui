defmodule SduiDemoWeb.Storybook.Layouts.TwoColumnLayout do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &AshSDUI.Components.SDUIRoot.render/1

  def variations do
    [
      %Variation{
        id: :sidebar_main,
        description: "Two-column layout with sidebar and main content",
        attributes: %{
          tree: build_two_column_tree()
        }
      }
    ]
  end

  defp build_two_column_tree do
    root =
      AshSDUI.Layout.Builder.node("Layouts.TwoColumnLayout@v1",
        children: [
          AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.UserUI, region: :sidebar),
          AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.PostUI, region: :main)
        ]
      )

    AshSDUI.Layout.Builder.to_tree(root)
  end
end
