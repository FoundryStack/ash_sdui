defmodule SduiDemoWeb.Storybook.Components.EditorialPostsPage do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &SduiDemoWeb.Components.EditorialPostsPage.render/1

  def variations do
    [
      %Variation{
        id: :with_featured_story,
        description: "Editorial posts index page driven by a recipe-provided props payload",
        attributes: %{
          props: %{
            title: "AshSDUI Journal",
            subtitle:
              "An example of a generated screen that still gets a strongly customized surface.",
            featured: %{
              id: "featured-1",
              title: "A generated screen that still feels product-shaped",
              excerpt:
                "The index uses AshSDUI.LiveResource for lifecycle and an app-side recipe for page composition.",
              published_at: ~U[2026-06-12 06:00:00Z],
              author_name: "demo_author",
              status: "Published",
              read_path: "/posts/featured-1",
              edit_path: "/posts/featured-1/edit"
            },
            posts: [
              %{
                id: "post-2",
                title: "Storybook parity matters",
                excerpt: "A shared CSS path keeps the app and previews visually aligned.",
                published_at: ~U[2026-06-11 06:00:00Z],
                author_name: "design_ops",
                status: "Published",
                read_path: "/posts/post-2",
                edit_path: "/posts/post-2/edit"
              },
              %{
                id: "post-3",
                title: "Recipes over hand-built index pages",
                excerpt:
                  "This demonstrates the app-side customization seam without giving up the generated engine.",
                published_at: nil,
                author_name: "builder",
                status: "Draft",
                read_path: "/posts/post-3",
                edit_path: "/posts/post-3/edit"
              }
            ]
          }
        }
      }
    ]
  end
end
