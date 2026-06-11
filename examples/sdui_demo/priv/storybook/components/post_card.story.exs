defmodule SduiDemoWeb.Storybook.Components.PostCard do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &SduiDemoWeb.Components.PostCard.render/1

  def variations do
    [
      %Variation{
        id: :with_author_comments,
        description: "PostCard with author and comment children",
        attributes: %{
          subject: %{
            id: "1",
            title: "Getting Started with SDUI",
            body: "Server-driven UI lets you change layouts without redeployment.",
            published_at: DateTime.utc_now()
          },
          props: %{},
          region: :default,
          children: %{
            author: [
              SduiDemoWeb.Components.UserCard.render(%{
                subject: %{username: "alice", email: "alice@example.com", avatar_url: nil},
                props: %{},
                region: :author,
                children: %{}
              })
            ],
            comments: [
              SduiDemoWeb.Components.CommentItem.render(%{
                subject: %{id: "1", body: "Great explanation!", posted_at: DateTime.utc_now()},
                props: %{},
                region: :comments,
                children: %{}
              })
            ]
          }
        }
      },
      %Variation{
        id: :draft,
        description: "Draft post without published_at",
        attributes: %{
          subject: %{
            id: "2",
            title: "Draft Post",
            body: "This post is not yet published.",
            published_at: nil
          },
          props: %{},
          region: :default,
          children: %{}
        }
      },
      %Variation{
        id: :no_subject,
        description: "PostCard with no subject loaded",
        attributes: %{
          subject: nil,
          props: %{},
          region: :default,
          children: %{}
        }
      }
    ]
  end
end
