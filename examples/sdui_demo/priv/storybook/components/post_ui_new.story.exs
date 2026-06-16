defmodule SduiDemoWeb.Storybook.Components.PostUINew do
  @moduledoc """
  Generated create-form story for the PostUI view.
  """

  use AshSDUI.Storybook,
    ui: SduiDemo.UI.Resources.PostUI,
    view: :new,
    form:
      SduiDemo.Blog.Post
      |> AshPhoenix.Form.for_create(:create, domain: SduiDemo.Blog, as: "post")
      |> Phoenix.Component.to_form()
end
