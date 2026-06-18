defmodule SduiDemoWeb.Live.LiveFeedLive do
  use AshSDUI.LiveResource,
    ui: SduiDemo.UI.Resources.FeedUI,
    view: :index,
    domain: SduiDemo.Blog,
    pubsub_server: SduiDemo.PubSub

  @topic "sdui_demo:live_feed"

  def ash_sdui_context(_params, _session, _socket) do
    %{
      assigns: %{
        feed_seed: [
          %{
            id: "feed-1",
            title: "Initial collection snapshot",
            body: "The binding started with assign-backed seed data.",
            status: "seed"
          },
          %{
            id: "feed-2",
            title: "Subscription is ready",
            body: "PubSub updates can append, merge, or remove items.",
            status: "live"
          }
        ]
      }
    }
  end

  def ash_sdui_view_opts(_mode, _params, _session, _socket) do
    [
      recipe_overrides: [
        toolbar: [props: %{class: "justify-between items-center"}],
        content: [component: "AshSDUI.StreamList@v1", props: %{binding_name: :collection}]
      ]
    ]
  end

  def handle_event("feed_append", _params, socket) do
    message =
      {:ash_sdui_event, :feed_update,
       %{
         operation: :append,
         item: %{
           id: "feed-#{System.unique_integer([:positive])}",
           title: "Appended item",
           body: "A generic collection update appended a record through the binding runtime.",
           status: "append"
         }
       }}

    apply_local_update(socket, message)
  end

  def handle_event("feed_merge", _params, socket) do
    case List.first(socket.assigns.records || []) do
      nil ->
        {:noreply, socket}

      first ->
        message =
          {:ash_sdui_event, :feed_update,
           %{
             operation: :merge,
             item: %{
               id: first.id,
               title: "#{first.title} (merged)",
               body: "The first item was updated in place via the merge strategy.",
               status: "merge"
             }
           }}

        apply_local_update(socket, message)
    end
  end

  def handle_event("feed_remove", _params, socket) do
    case List.first(socket.assigns.records || []) do
      nil ->
        {:noreply, socket}

      first ->
        message = {:ash_sdui_event, :feed_update, %{operation: :remove, id: first.id}}

        apply_local_update(socket, message)
    end
  end

  def handle_event(event, params, socket) do
    AshSDUI.LiveResource.handle_resource_event(__MODULE__, event, params, socket)
  end

  defp apply_local_update(socket, message) do
    Phoenix.PubSub.broadcast_from(SduiDemo.PubSub, self(), @topic, message)

    case AshSDUI.LiveResource.handle_resource_info(__MODULE__, message, socket) do
      {:noreply, next_socket} -> {:noreply, next_socket}
    end
  end
end
