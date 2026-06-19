# How to Build Nested Layouts

Use this guide when a screen should render multiple related resources in one
layout tree.

For stored and published layouts, see
[How to Work with SDUI Layouts](work_with_sdui_layouts.md).

## Start with `Builder.resource/2`

Prefer `AshSDUI.Layout.Builder.resource/2` so the node can derive its component
and `for_resource` metadata from the UI module.

```elixir
alias AshSDUI.Layout.Builder

root =
  Builder.resource(MyApp.UI.PostUI,
    id: "post-show-card-#{post.id}",
    subject_id: post.id
  )
```

This is the preferred entrypoint for authoring nested layout trees.

## Add child resources by region

Attach related resources as child nodes in named regions.

```elixir
Builder.resource(MyApp.UI.PostUI,
  id: "post-show-card-#{post.id}",
  subject_id: post.id,
  children: [
    Builder.resource(MyApp.UI.UserUI,
      id: "post-show-author-#{post.id}",
      region: :author,
      subject_id: post.author_id
    )
  ]
)
```

This is a good fit for structures such as:

- author cards inside posts
- sidebar records beside a main record
- nested detail views

## Build one node per related record with `resources/3`

Use `Builder.resources/3` when a related collection should become one child node
per record.

```elixir
comment_nodes =
  Builder.resources(MyApp.UI.CommentUI, comments,
    id_prefix: "post-show-comment",
    region: :comments
  )

root =
  Builder.resource(MyApp.UI.PostUI,
    subject_id: post.id,
    children: comment_nodes
  )
```

This is the preferred path for repeated nested regions such as comments,
activity items, or related records.

## Compose multiple nested regions

You can mix singular and repeated children in one tree.

```elixir
Builder.resource(MyApp.UI.PostUI,
  subject_id: post.id,
  children: [
    Builder.resource(MyApp.UI.UserUI,
      region: :author,
      subject_id: post.author_id
    )
    | Builder.resources(MyApp.UI.CommentUI, comments,
        id_prefix: "comment",
        region: :comments
      )
  ]
)
```

This pattern is already proven in the demo layouts for posts, authors, and
comments.

## Assign the nested layout at runtime

Use `AshSDUI.LiveScreen.assign_layout/3` when the nested tree is built from
current assigns or records inside a LiveView.

```elixir
defp assign_post_state(socket, post, comments) do
  {layout_name, root} = MyApp.UI.Layouts.PostShowLayout.build(post, comments)

  AshSDUI.LiveScreen.assign_layout(socket, layout_name, root)
end
```

Use this path when the tree should be rebuilt on the fly instead of stored.
