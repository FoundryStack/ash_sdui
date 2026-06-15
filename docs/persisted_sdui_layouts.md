# Persisted and Custom `:sdui` Layouts

This guide covers the three layout paths in AshSDUI:

- generated views with `layout: :sdui`
- ephemeral runtime layouts
- persisted named layouts backed by `UINode` records

## Generated `layout: :sdui`

This starts from view metadata.

```elixir
view :index,
  recipe: :editorial_blog,
  layout: :sdui,
  title: "AshSDUI Journal"
```

When `AshSDUI.LiveResource` mounts that view, it calls `AshSDUI.View.to_layout/2`
and renders the returned layout tree through `SDUIRoot`.

Use this when a recipe can derive the layout from the resolved view.

## Ephemeral Runtime Layouts

This starts from a LiveView that builds a layout tree directly from current
assigns, records, or mode switches.

```elixir
{layout_name, root} = MyApp.UI.Layouts.PostShowLayout.build(post, comments, mode: mode)
socket = AshSDUI.LiveScreen.assign_layout(socket, layout_name, root)
```

Use this when the layout is rebuilt on the fly and does not need persistence.

## Persisted Named Layouts

This starts from a named layout tree that should be stored and later reloaded.

```elixir
root =
  AshSDUI.Layout.Builder.resource(MyApp.UI.Resources.PostUI,
    children: [
      AshSDUI.Layout.Builder.node("Sidebar.RelatedPosts@v1", region: :sidebar)
    ]
  )

AshSDUI.Layout.save("post-index", root, status: :draft)
AshSDUI.Layout.publish("post-index")
```

Use this when a layout should survive restarts, participate in draft/publish
workflow, or eventually be edited outside code.

## Public Persistence API

Prefer the small public API:

1. `AshSDUI.Layout.save/3`
2. `AshSDUI.Layout.fetch/2`
3. `AshSDUI.Layout.load_nodes/2`
4. `AshSDUI.Layout.publish/2`

Prefer those functions over `AshSDUI.Layout.Persistence`.
