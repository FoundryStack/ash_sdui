# How to Add Live Bindings

Use this guide when a generated or layout-rendered screen should consume a live
data source instead of only snapshot resource reads.

For the binding contract, see [Runtime Contract](../reference/runtime_contract.md).

## Define a live binding

Use `ui_binding` with a live-capable source such as PubSub.

```elixir
ui_binding :collection,
  source:
    {:pubsub, "ash_sdui:test_feed",
     [source: {:assign, :seed_feed}, event: :feed_update, reducer: :stream_event, key: :id]},
  many?: true,
  default: [],
  refresh: :subscription,
  update: :append
```

This gives the screen a named runtime source with subscription refresh behavior.

## Keep the view generated

A live binding can still live inside a generated screen.

```elixir
view :index, recipe: :collection, read_action: :read, layout: :sdui, title: "Live Feed"
```

Use `layout: :sdui` when the screen should stay generated but render through a
runtime-aware component.

## Swap the content component

Use `ash_sdui_view_opts/4` when the collection should render through a live
runtime component.

```elixir
def ash_sdui_view_opts(_mode, _params, _session, _socket) do
  [
    recipe_overrides: [
      content: [component: "AshSDUI.StreamList@v1", props: %{binding_name: :collection}]
    ]
  ]
end
```

This keeps the binding declarative while letting the rendered component consume
`@bound_value` or the named binding.

## Seed initial runtime data

Use `ash_sdui_context/3` when the live binding should start from a runtime seed.

```elixir
def ash_sdui_context(_params, _session, _socket) do
  %{
    assigns: %{
      seed_feed: [
        %{id: "feed-1", title: "Seed item", body: "Initial body", status: "seed"}
      ]
    }
  }
end
```

This gives the screen an initial rendered state before live updates arrive.

## Choose an update strategy

Current normalized update strategies include:

- `:replace`
- `:append`
- `:prepend`
- `:merge`
- `:remove`

Pick the strategy that matches how live events should change the binding value.

## Use this guide for

- live collections
- subscription-backed dashboards
- refreshable runtime panels
- generated screens that need stream-style updates

For visual proof of these scenarios, continue with
[How to Render Generated Views in Storybook](render_generated_views_in_storybook.md).
