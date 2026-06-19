defmodule SduiDemoWeb.Storybook.Components.ResourceActions do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &SduiDemoWeb.Components.ResourceActions.render/1

  def variations do
    post = %{id: "post-1", title: "A storybook post", published_at: nil}

    [
      %Variation{
        id: :post_actions,
        description: "Buttons generated from PostUI action metadata",
        attributes: %{
          resource: SduiDemo.UI.Resources.PostUI,
          subject: post,
          overrides: %{
            read: %{kind: :link, to: "/posts/post-1"},
            update: %{kind: :link, to: "/posts/post-1/edit"},
            publish: %{kind: :event, event: "publish"},
            destroy: %{kind: :event, event: "delete", confirm: "Delete this post?"}
          }
        }
      }
    ]
  end
end
