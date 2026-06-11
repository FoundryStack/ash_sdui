defmodule SduiDemoWeb.Storybook.Layouts.PostShowLayout do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &AshSDUI.Components.SDUIRoot.render/1

  def variations do
    [
      %Variation{
        id: :standard,
        description: "Standard layout: post card with author and comments nested",
        attributes: %{
          tree: build_standard_tree()
        }
      },
      %Variation{
        id: :blog,
        description: "Blog layout: author sidebar + post main",
        attributes: %{
          tree: build_blog_tree()
        }
      },
      %Variation{
        id: :minimal,
        description: "Minimal layout: post card only, no children",
        attributes: %{
          tree: build_minimal_tree()
        }
      }
    ]
  end

  defp build_standard_tree do
    AshSDUI.Mock.tree_node("PostCard@v1",
      subject_resource: "SduiDemo.Blog.Post",
      subject_id: "first",
      children: [
        AshSDUI.Mock.tree_node("UserCard@v1",
          region: :author,
          subject_resource: "SduiDemo.Accounts.User",
          subject_id: "first"),
        AshSDUI.Mock.tree_node("CommentItem@v1",
          region: :comments,
          subject_resource: "SduiDemo.Blog.Comment",
          subject_id: "first"),
        AshSDUI.Mock.tree_node("CommentItem@v1",
          region: :comments,
          subject_resource: "SduiDemo.Blog.Comment",
          subject_id: "second")
      ])
  end

  defp build_blog_tree do
    AshSDUI.Mock.tree_node("Layouts.TwoColumnLayout@v1",
      children: [
        AshSDUI.Mock.tree_node("UserCard@v1",
          region: :sidebar,
          subject_resource: "SduiDemo.Accounts.User",
          subject_id: "first"),
        AshSDUI.Mock.tree_node("PostCard@v1",
          region: :main,
          subject_resource: "SduiDemo.Blog.Post",
          subject_id: "first",
          children: [
            AshSDUI.Mock.tree_node("CommentItem@v1",
              region: :comments,
              subject_resource: "SduiDemo.Blog.Comment",
              subject_id: "first"),
            AshSDUI.Mock.tree_node("CommentItem@v1",
              region: :comments,
              subject_resource: "SduiDemo.Blog.Comment",
              subject_id: "second")
          ])
      ])
  end

  defp build_minimal_tree do
    AshSDUI.Mock.tree_node("PostCard@v1",
      subject_resource: "SduiDemo.Blog.Post",
      subject_id: "first")
  end
end
