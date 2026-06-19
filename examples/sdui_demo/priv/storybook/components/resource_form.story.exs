defmodule SduiDemoWeb.Storybook.Components.ResourceForm do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &SduiDemoWeb.Components.ResourceForm.render/1

  def variations do
    form =
      SduiDemo.Blog.Post
      |> AshPhoenix.Form.for_create(:create, domain: SduiDemo.Blog, as: "post")
      |> Phoenix.Component.to_form()

    [
      %Variation{
        id: :post_create,
        description: "Form fields generated from PostUI metadata and the Post create action",
        attributes: %{
          form: form,
          resource: SduiDemo.UI.Resources.PostUI,
          action: :create,
          change_event: "validate",
          submit_event: "save"
        }
      }
    ]
  end
end
