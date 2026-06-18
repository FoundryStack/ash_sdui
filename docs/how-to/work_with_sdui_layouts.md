# How to Work with SDUI Layouts

Use this guide when you need to build, assign, store, or publish layout trees.

For the layout model behind these tasks, see
[Authoring Model](../explanation/authoring_model.md). For the public API list,
see [Public API Map](../reference/public_api.md).

## Build a layout tree from UI metadata

Prefer `AshSDUI.Layout.Builder.resource/2` and `resources/3` so the layout can
derive the default component and `for_resource` metadata from the UI module.

```elixir
alias AshSDUI.Layout.Builder

root =
  Builder.resource(MyApp.UI.PostUI,
    region: :main,
    children: [
      Builder.node("Posts.ActivityFeed@v1", region: :sidebar, binding: :feed)
    ]
  )
```

Use `resources/3` when you want one child node per record.

```elixir
children =
  Builder.resources(MyApp.UI.CommentUI, comments,
    region: :content
  )

root =
  Builder.resource(MyApp.UI.PostUI,
    children: children
  )
```

## Register a code-authored layout

Register a named layout when the tree should be available by name in code.

```elixir
AshSDUI.Layout.register("post-dashboard", root)
```

Fetch the authored definition tree through the public layout API.

```elixir
AshSDUI.Layout.fetch("post-dashboard")
```

## Assign an ephemeral layout in a LiveView

Use `AshSDUI.LiveScreen.assign_layout/3` when a LiveView rebuilds a layout from
current assigns, records, or mode switches.

```elixir
def handle_params(%{"id" => id}, _uri, socket) do
  post = load_post!(id)
  comments = load_comments!(id)
  {layout_name, root} = MyApp.UI.Layouts.PostShowLayout.build(post, comments)

  {:noreply, AshSDUI.LiveScreen.assign_layout(socket, layout_name, root)}
end
```

This path registers, evicts, renders, and assigns the layout in one step.

## Save and publish a persisted layout

Use the public `AshSDUI.Layout` API when the layout should survive restarts or
participate in a draft/publish workflow.

```elixir
root =
  AshSDUI.Layout.Builder.resource(MyApp.UI.PostUI,
    children: [
      AshSDUI.Layout.Builder.node("Posts.Related@v1", region: :sidebar)
    ]
  )

AshSDUI.Layout.save("post-show", root, status: :draft)
AshSDUI.Layout.publish("post-show")
```

Fetch a stored layout through the same public API.

```elixir
AshSDUI.Layout.fetch("post-show", source: :stored)
```

## Use a custom persisted node resource

Pass `node_resource:` when production storage should use a compatible Ash
resource instead of `AshSDUI.UINode`.

```elixir
AshSDUI.Layout.save("post-show", root,
  status: :draft,
  node_resource: MyApp.SDUI.Node
)

AshSDUI.Layout.fetch("post-show",
  source: :stored,
  node_resource: MyApp.SDUI.Node
)
```

Keep `AshSDUI.Layout.Persistence` out of new examples and new code paths. Use
`fetch/2`, `register/2`, `save/3`, and `publish/2` as the public interface.

## Add runtime-aware node metadata

Attach small runtime hooks to the node when a component should consume one slice
of the shared runtime contract.

```elixir
Builder.node("Posts.MetricGrid@v1",
  binding: :metrics,
  refresh: :manual,
  variant: :compact,
  state_key: :workflow
)
```

Use these fields for declarative component inputs:

- `binding`
- `refresh`
- `variant`
- `state_key`
