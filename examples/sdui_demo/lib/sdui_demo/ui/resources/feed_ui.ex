defmodule SduiDemo.UI.Resources.FeedUI do
  use AshSDUI.Resource.Standalone

  sdui do
    for_resource(SduiDemo.Blog.Post)

    view(:index, recipe: :collection, read_action: :read, layout: :sdui, title: "Live Feed")

    ui_binding(:collection,
      source:
        {:pubsub, "sdui_demo:live_feed",
         [
           source: {:assign, :feed_seed},
           event: :feed_update,
           reducer: :stream_event,
           key: :id
         ]},
      many?: true,
      default: [],
      refresh: :subscription,
      update: :append
    )

    ui_intent(:append,
      style: :primary,
      label: "Append Item",
      target: {:event, "feed_append"},
      placement: :toolbar
    )

    ui_intent(:merge,
      style: :secondary,
      label: "Merge First",
      target: {:event, "feed_merge"},
      placement: :toolbar,
      enabled_when: :collection
    )

    ui_intent(:remove,
      style: :destructive,
      label: "Remove First",
      target: {:event, "feed_remove"},
      placement: :toolbar,
      enabled_when: :collection
    )
  end
end
