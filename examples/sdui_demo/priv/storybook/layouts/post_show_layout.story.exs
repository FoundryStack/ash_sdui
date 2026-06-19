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
    root =
      AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.PostUI,
        subject_id: "first",
        children: [
          AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.UserUI,
            region: :author,
            subject_id: "first"
          ),
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

    AshSDUI.Layout.Builder.to_tree(root)
  end

  defp build_blog_tree do
    root =
      AshSDUI.Layout.Builder.node("Layouts.TwoColumnLayout@v1",
        children: [
          AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.UserUI,
            region: :sidebar,
            subject_id: "first"
          ),
          AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.PostUI,
            region: :main,
            subject_id: "first",
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

  defp build_minimal_tree do
    AshSDUI.Layout.Builder.resource(SduiDemo.UI.Resources.PostUI, subject_id: "first")
    |> AshSDUI.Layout.Builder.to_tree()
  end
end
