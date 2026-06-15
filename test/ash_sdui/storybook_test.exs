defmodule AshSDUI.StorybookTest do
  use ExUnit.Case, async: false

  alias AshSDUI.TestFixtures.LiveResourceBlog, as: Blog
  alias AshSDUI.TestFixtures.LiveResourcePost, as: Post
  alias AshSDUI.TestFixtures.LiveResourcePostUI, as: PostUI

  defp html(rendered) do
    rendered
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  setup do
    Ash.DataLayer.Ets.stop(Post)
    :ok
  end

  test "storybook can build a generated view tree from ui metadata" do
    assert {:ok, post} =
             Ash.create(Post, %{title: "Storybook Post"}, action: :create, domain: Blog)

    assigns =
      AshSDUI.Storybook.story_assigns(
        ui: PostUI,
        view: :index,
        bindings: %{collection: [post]}
      )

    output = html(AshSDUI.Storybook.render(Map.put(assigns, :__changed__, nil)))

    assert output =~ "Storybook Post"
    assert output =~ "New Post"
  end
end
