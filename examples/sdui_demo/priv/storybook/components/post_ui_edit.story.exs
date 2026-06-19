defmodule SduiDemoWeb.Storybook.Components.PostUIEdit do
  @moduledoc """
  Generated edit-form story for the PostUI view.
  """

  alias SduiDemo.Blog.Post

  use AshSDUI.Storybook,
    ui: SduiDemo.UI.Resources.PostUI,
    view: :edit,
    bindings: %{
      record: %Post{
        id: "story-post-edit-1",
        title: "Generated edit view",
        body: "Storybook form preview for the edit path.",
        published_at: nil
      }
    },
    params: %{"id" => "story-post-edit-1"},
    form:
      Post
      |> struct(
        id: "story-post-edit-1",
        title: "Generated edit view",
        body: "Storybook form preview for the edit path.",
        published_at: nil
      )
      |> AshPhoenix.Form.for_update(:update, domain: SduiDemo.Blog, as: "post")
      |> Phoenix.Component.to_form()
end
