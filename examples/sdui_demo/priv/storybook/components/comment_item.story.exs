defmodule SduiDemoWeb.Storybook.Components.CommentItem do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &SduiDemoWeb.Components.CommentItem.render/1

  def variations do
    [
      %Variation{
        id: :with_timestamp,
        description: "Comment with body and timestamp",
        attributes: %{
          subject: %{
            id: "1",
            body: "This is a great example of server-driven UI in action!",
            posted_at: DateTime.utc_now()
          },
          props: %{},
          region: :comments,
          children: %{}
        }
      },
      %Variation{
        id: :no_subject,
        description: "Comment unavailable (nil subject)",
        attributes: %{
          subject: nil,
          props: %{},
          region: :comments,
          children: %{}
        }
      }
    ]
  end
end
