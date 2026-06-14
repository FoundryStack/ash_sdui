defmodule AshSDUI.LiveResourceTest do
  use ExUnit.Case, async: false

  alias AshSDUI.TestFixtures.LiveResourceBlog, as: Blog
  alias AshSDUI.TestFixtures.LiveResourcePost, as: Post
  alias AshSDUI.TestFixtures.LiveResourcePostUI, as: PostUI

  defmodule PostsLive do
    use AshSDUI.LiveResource, resource: PostUI, screen: :index, domain: Blog
  end

  defmodule HookedPostsLive do
    use AshSDUI.LiveResource, resource: PostUI, screen: :index, domain: Blog

    def ash_sdui_context(_params, _session, _socket), do: %{audience: :staff}

    def ash_sdui_screen_opts(_mode, _params, _session, _socket) do
      [
        recipe_overrides: [
          empty_state: [title: "No posts yet", body: "Write the first one."],
          toolbar: false,
          content: [props: %{class: "stacked-layout"}],
          fields: %{title: %{label: "Headline"}},
          actions: %{create: %{label: "Compose Post"}}
        ]
      ]
    end

    def ash_sdui_load_assigns(_mode, _params, _socket) do
      %{page_title: "Hooked Posts", demo_flag: true}
    end
  end

  setup do
    Ash.DataLayer.Ets.stop(Post)
    :ok
  end

  test "generated index LiveView mounts with resolved screen and records" do
    assert {:ok, socket} = PostsLive.mount(%{}, %{}, %Phoenix.LiveView.Socket{})

    assert socket.assigns.ash_sdui_resource == Post
    assert socket.assigns.ash_sdui_screen.mode == :index
    assert socket.assigns.page_title == "Posts"
    assert socket.assigns.records == []
    assert socket.assigns.ash_sdui_opts[:domain] == Blog
    assert socket.assigns.ash_sdui_opts[:resource] == PostUI
    refute match?({:__aliases__, _, _}, socket.assigns.ash_sdui_opts[:domain])
    refute match?({:__aliases__, _, _}, socket.assigns.ash_sdui_opts[:resource])
  end

  test "live resource exports mount_resource/7 for generated LiveViews" do
    assert function_exported?(AshSDUI.LiveResource, :mount_resource, 7)

    assert {:ok, socket} =
             AshSDUI.LiveResource.mount_resource(
               PostsLive,
               PostUI,
               :index,
               [resource: PostUI, screen: :index, domain: Blog],
               %{},
               %{},
               %Phoenix.LiveView.Socket{}
             )

    assert socket.assigns.ash_sdui_resource == Post
    assert socket.assigns.page_title == "Posts"
  end

  test "generated LiveView hooks can extend context and assigns" do
    assert {:ok, socket} = HookedPostsLive.mount(%{}, %{}, %Phoenix.LiveView.Socket{})

    assert socket.assigns.ash_sdui_screen.context.audience == :staff

    assert Enum.find(socket.assigns.ash_sdui_screen.fields, &(&1.name == :title)).label ==
             "Headline"

    assert Enum.find(socket.assigns.ash_sdui_screen.actions, &(&1.name == :create)).label ==
             "Compose Post"

    assert socket.assigns.ash_sdui_screen.assigns.empty_state == "No posts yet"
    assert socket.assigns.ash_sdui_screen.assigns.empty_state_body == "Write the first one."
    assert socket.assigns.ash_sdui_screen.assigns.recipe_overrides[:toolbar][:skip?] == true
    assert socket.assigns.page_title == "Hooked Posts"
    assert socket.assigns.demo_flag == true
  end
end
