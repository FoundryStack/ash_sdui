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
    AshSDUI.Mock.tree_node("Layouts.TwoColumnLayout@v1",
      children: [
        AshSDUI.Mock.tree_node("UserCard@v1",
          region: :sidebar,
          subject_resource: "SduiDemo.Accounts.User",
          subject_id: "first"),
        AshSDUI.Mock.tree_node("PostCard@v1",
          region: :main,
          subject_resource: "SduiDemo.Blog.Post",
          subject_id: "first")
      ])
  end
end
