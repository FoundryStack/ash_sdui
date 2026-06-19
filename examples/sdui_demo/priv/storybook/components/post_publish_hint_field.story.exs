defmodule SduiDemoWeb.Storybook.Components.PostPublishHintField do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &SduiDemoWeb.Components.PostPublishHintField.render/1

  def variations do
    form =
      SduiDemo.Blog.Post
      |> AshPhoenix.Form.for_create(:create, domain: SduiDemo.Blog, as: "post")
      |> Phoenix.Component.to_form()

    [
      %Variation{
        id: :default,
        description: "Custom field component used by the metadata-driven post form",
        attributes: %{
          form: form,
          field: %{name: :body, label: "Content"},
          value: "",
          errors: []
        }
      }
    ]
  end
end
