defmodule SduiDemoWeb.Storybook.Layouts.BlogLayout do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &AshSDUI.Components.SDUIRoot.render/1

  def variations do
    [
      %Variation{
        id: :blog_post,
        description: "Blog layout: author sidebar + post main with comments",
        attributes: %{
          tree: build_blog_tree()
        }
      }
    ]
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
end
