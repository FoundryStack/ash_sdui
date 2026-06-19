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
    root =
      AshSDUI.Layout.Builder.node("Layouts.TwoColumnLayout@v1",
        children: [
          AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.UserUI, region: :sidebar),
          AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.PostUI,
            region: :main,
            children: [
              AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.CommentUI,
                id: "comment-1",
                region: :comments
              ),
              AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.CommentUI,
                id: "comment-2",
                region: :comments,
                order: 1,
                subject_id: "second"
              )
            ]
          )
        ]
      )

    AshSDUI.Layout.Builder.to_tree(root)
  end
end
