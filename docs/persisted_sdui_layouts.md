# Persisted and custom `:sdui` layouts

This guide covers the part of AshSDUI that is easiest to blur together:

- generated screens with `layout: :sdui`
- ephemeral runtime layouts
- persisted named layouts backed by `UINode` records

They all end in an SDUI tree, but they start from different authoring models.

## The three paths

### 1. Generated `layout: :sdui`

This starts from screen metadata.

```elixir
screen(:index,
  recipe: :editorial_blog,
  layout: :sdui,
  title: "AshSDUI Journal"
)
```

When `AshSDUI.LiveResource` mounts that screen, it calls `Screen.to_layout/2`
and renders the returned layout tree through `SDUIRoot`.

Use this when a recipe can derive the layout from the resolved screen.

### 2. Ephemeral runtime layouts

This starts from a LiveView that builds a layout tree directly from current
assigns, records, or mode switches.

```elixir
{layout_name, root} = MyApp.UI.Layouts.PostShowLayout.build(post, comments, mode: mode)
socket = AshSDUI.LiveScreen.assign_layout(socket, layout_name, root)
```

Use this when the layout is rebuilt on the fly and does not need persistence.

### 3. Persisted named layouts

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

## Persisted layout lifecycle

The public API for stored layouts is intentionally small:

1. `AshSDUI.Layout.save/3`
2. `AshSDUI.Layout.fetch/2`
3. `AshSDUI.Layout.load_nodes/2`
4. `AshSDUI.Layout.publish/2`

Prefer those functions over `AshSDUI.Layout.Persistence`, which is kept only as
compatibility glue.

### Draft and publish

By default:

- `save/3` writes nodes as `:draft`
- `fetch/2` reads stored layouts with `status: :published`
- `load_nodes/2` also defaults to `status: :published`

That means draft layouts are invisible unless you ask for them explicitly:

```elixir
AshSDUI.Layout.fetch("post-index", source: :stored, status: :draft)
AshSDUI.Renderer.to_tree("post-index", source: :stored, status: :draft)
```

Publish when the draft should become the default stored version:

```elixir
AshSDUI.Layout.publish("post-index")
```

## Registered vs stored lookup

`AshSDUI.Layout.fetch/2` defaults to `source: :any`, which checks:

1. registered code layouts first
2. stored layouts second

That is convenient, but it also means a registered layout with the same name
will win over a stored one. If you need the persisted layout specifically, say
so at the lookup boundary:

```elixir
AshSDUI.Layout.fetch("post-index", source: :stored)
AshSDUI.Renderer.to_tree("post-index", source: :stored)
```

That same rule applies when using `use AshSDUI`:

```elixir
defmodule MyAppWeb.StoredLayoutLive do
  use AshSDUI,
    lookup: {:static, "post-index"},
    source: :stored,
    status: :draft
end
```

## Using a custom `node_resource:`

`AshSDUI.UINode` is fine for tests, demos, and local prototypes. Production apps
that want database-backed storage should define a compatible Ash resource and
pass it at the API boundary:

```elixir
AshSDUI.Layout.save("post-index", root, node_resource: MyApp.SDUI.Node)
AshSDUI.Layout.publish("post-index", node_resource: MyApp.SDUI.Node)
AshSDUI.Renderer.to_tree("post-index", node_resource: MyApp.SDUI.Node)
```

The custom resource should match the built-in node contract closely:

- `component_name`
- `static_props`
- `subject_resource`
- `subject_id`
- `region`
- `order`
- `status`
- `name`
- `parent_id`

And it should support the expected actions:

- `:read`
- `:create`
- `:destroy`
- `:publish`

If you also expose updates or archival in your app, keep their semantics aligned
with the built-in resource so layout tooling does not drift.

## When not to persist

Do not persist a layout just because the final render uses `SDUIRoot`.

Stay with generated `layout: :sdui` when:

- the layout can be derived from the screen every request
- recipe overrides are enough
- there is no separate layout publication flow

Stay with `assign_layout/3` when:

- the layout depends on current runtime state
- the tree is rebuilt per event or per view mode
- you do not need draft/publish behavior

Persist only when the layout itself is durable application data.
