defmodule AshSDUI.LiveResourceTest do
  use ExUnit.Case, async: false

  alias AshSDUI.TestFixtures.LiveResourceBlog, as: Blog
  alias AshSDUI.TestFixtures.LiveCollectionPostUI
  alias AshSDUI.TestFixtures.LiveResourcePost, as: Post
  alias AshSDUI.TestFixtures.LiveResourcePostUI, as: PostUI

  defmodule PostsLive do
    use AshSDUI.LiveResource, ui: PostUI, view: :index, domain: Blog
  end

  defmodule HookedPostsLive do
    use AshSDUI.LiveResource, ui: PostUI, view: :index, domain: Blog

    def ash_sdui_context(_params, _session, _socket), do: %{audience: :staff}

    def ash_sdui_view_opts(_mode, _params, _session, _socket) do
      [
        recipe_overrides: [
          empty_state: [title: "No posts yet", body: "Write the first one."],
          toolbar: false,
          content: [props: %{class: "stacked-layout"}],
          fields: %{title: %{label: "Headline"}},
          intents: %{create: %{label: "Compose Post"}}
        ]
      ]
    end

    def ash_sdui_load_assigns(_mode, _params, _socket) do
      %{page_title: "Hooked Posts", demo_flag: true}
    end
  end

  defmodule LayoutPostsLive do
    use AshSDUI.LiveResource,
      ui: PostUI,
      view: :index,
      domain: Blog,
      assigns: %{layout: :sdui}
  end

  defmodule FeedLive do
    use AshSDUI.LiveResource,
      ui: LiveCollectionPostUI,
      view: :index,
      domain: Blog,
      pubsub_server: AshSDUI.TestPubSub

    def ash_sdui_context(_params, _session, _socket) do
      %{
        assigns: %{
          seed_feed: [
            %{id: "feed-1", title: "Seed item", body: "Initial body", status: "seed"}
          ]
        }
      }
    end

    def ash_sdui_view_opts(_mode, _params, _session, _socket) do
      [
        recipe_overrides: [
          content: [component: "AshSDUI.StreamList@v1", props: %{binding_name: :collection}]
        ]
      ]
    end
  end

  defp html(rendered) do
    rendered
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  setup do
    Application.ensure_all_started(:phoenix_pubsub)
    Ash.DataLayer.Ets.stop(Post)
    start_supervised!({Phoenix.PubSub, name: AshSDUI.TestPubSub})
    :ok
  end

  test "generated index LiveView mounts with resolved view and records" do
    assert {:ok, socket} = PostsLive.mount(%{}, %{}, %Phoenix.LiveView.Socket{})

    assert socket.assigns.ash_sdui_resource == Post
    assert socket.assigns.ash_sdui_ui == PostUI
    assert socket.assigns.ash_sdui_view.mode == :index
    assert socket.assigns.page_title == "Posts"
    assert socket.assigns.records == []
    assert socket.assigns.ash_sdui_opts[:domain] == Blog
    assert socket.assigns.ash_sdui_opts[:ui] == PostUI
    refute match?({:__aliases__, _, _}, socket.assigns.ash_sdui_opts[:domain])
    refute match?({:__aliases__, _, _}, socket.assigns.ash_sdui_opts[:ui])
  end

  test "live resource exports mount_resource/7 for generated LiveViews" do
    assert function_exported?(AshSDUI.LiveResource, :mount_resource, 7)

    assert {:ok, socket} =
             AshSDUI.LiveResource.mount_resource(
               PostsLive,
               PostUI,
               :index,
               [ui: PostUI, view: :index, domain: Blog],
               %{},
               %{},
               %Phoenix.LiveView.Socket{}
             )

    assert socket.assigns.ash_sdui_resource == Post
    assert socket.assigns.ash_sdui_ui == PostUI
    assert socket.assigns.page_title == "Posts"
  end

  test "generated LiveView hooks can extend context and assigns" do
    assert {:ok, socket} = HookedPostsLive.mount(%{}, %{}, %Phoenix.LiveView.Socket{})

    assert socket.assigns.ash_sdui_view.context.audience == :staff

    assert Enum.find(socket.assigns.ash_sdui_view.fields, &(&1.name == :title)).label ==
             "Headline"

    assert Enum.find(socket.assigns.ash_sdui_view.intents, &(&1.name == :create)).label ==
             "Compose Post"

    assert socket.assigns.ash_sdui_view.assigns.empty_state == "No posts yet"
    assert socket.assigns.ash_sdui_view.assigns.empty_state_body == "Write the first one."
    assert socket.assigns.ash_sdui_view.assigns.recipe_overrides[:toolbar][:skip?] == true
    assert socket.assigns.page_title == "Hooked Posts"
    assert socket.assigns.demo_flag == true
  end

  test "handle_params refresh reuses the shared runtime orchestration" do
    assert {:ok, _post} = Ash.create(Post, %{title: "Launch Post"}, action: :create, domain: Blog)
    assert {:ok, socket} = HookedPostsLive.mount(%{}, %{}, %Phoenix.LiveView.Socket{})

    assert {:noreply, refreshed_socket} =
             HookedPostsLive.handle_params(%{"search" => "Launch"}, "/posts?search=Launch", socket)

    assert refreshed_socket.assigns.ash_sdui_view.context.audience == :staff
    assert refreshed_socket.assigns.demo_flag == true
    assert refreshed_socket.assigns.page_title == "Hooked Posts"
    assert refreshed_socket.assigns.ash_sdui_uri == "/posts?search=Launch"
    assert refreshed_socket.assigns.records |> Enum.map(& &1.title) == ["Launch Post"]
  end

  test "layout :sdui renders through the generic view components with binding data" do
    assert {:ok, _post} = Ash.create(Post, %{title: "Launch Post"}, action: :create, domain: Blog)
    assert {:ok, socket} = LayoutPostsLive.mount(%{}, %{}, %Phoenix.LiveView.Socket{})

    output = html(AshSDUI.LiveResource.render_resource(socket.assigns))

    assert output =~ "generic-view"
    assert output =~ "Launch Post"
    assert output =~ "New Post"
  end

  test "generic selection and workflow events update runtime state" do
    assert {:ok, post} =
             Ash.create(Post, %{title: "Selectable Post"}, action: :create, domain: Blog)

    assert {:ok, socket} = PostsLive.mount(%{}, %{}, %Phoenix.LiveView.Socket{})

    assert {:noreply, selected_socket} =
             PostsLive.handle_event("select", %{"id" => post.id}, socket)

    assert selected_socket.assigns.ash_sdui_state.selected == [post.id]

    assert {:noreply, workflow_socket} =
             PostsLive.handle_event("workflow", %{"event" => "review"}, selected_socket)

    assert workflow_socket.assigns.ash_sdui_state.workflow.state == "review"
    assert workflow_socket.assigns.ash_sdui_view.state.workflow.state == "review"
  end

  test "live collection messages update only the subscribed binding runtime" do
    assert {:ok, socket} = FeedLive.mount(%{}, %{}, %Phoenix.LiveView.Socket{})

    assert Enum.map(socket.assigns.records, & &1.id) == ["feed-1"]
    assert socket.assigns.ash_sdui_state.refresh.collection.status == :ready

    assert {:noreply, appended_socket} =
             FeedLive.handle_info(
               {:ash_sdui_event, :feed_update,
                %{operation: :append, item: %{id: "feed-2", title: "Next item", status: "append"}}},
               socket
             )

    assert Enum.map(appended_socket.assigns.records, & &1.id) == ["feed-1", "feed-2"]
    assert appended_socket.assigns.ash_sdui_state.refresh.collection.status == :ready
    assert appended_socket.assigns.ash_sdui_view.state.refresh.collection.refreshed_at

    assert {:noreply, merged_socket} =
             FeedLive.handle_info(
               {:ash_sdui_event, :feed_update,
                %{
                  operation: :merge,
                  item: %{id: "feed-1", title: "Updated seed", status: "merge"}
                }},
               appended_socket
             )

    assert Enum.find(merged_socket.assigns.records, &(&1.id == "feed-1")).title == "Updated seed"
    assert Enum.map(merged_socket.assigns.records, & &1.id) == ["feed-1", "feed-2"]
  end
end
