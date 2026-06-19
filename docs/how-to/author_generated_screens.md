# How to Author Generated Screens

Use this guide when a screen should stay metadata-driven but you need more
control over presentation, assigns, or save behavior.

For the runtime concepts behind these tasks, see
[Runtime Model](../explanation/runtime_model.md). For the public API surface,
see [Public API Map](../reference/public_api.md).

## Keep the screen on `AshSDUI.LiveResource`

Start with `AshSDUI.LiveResource` when the screen still fits a generated
collection, detail, or form shape.

```elixir
defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :index,
    domain: MyApp.Blog
end
```

Stay on this path when the work is mostly:

- resource metadata
- generated forms
- query and binding declarations
- recipe-level presentation changes
- predictable before-save and after-save hooks

Step up to a custom recipe or custom LiveView only when the generated host no
longer matches the screen's coordination needs.

## Adjust presentation with `ash_sdui_view_opts/4`

Use `ash_sdui_view_opts/4` for labels, copy, recipe selection, and recipe-level
props.

```elixir
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
```

Use this hook when you want to keep the generated screen but need a different
title, empty state, field label, intent label, or shell props.

## Add screen-specific assigns with `ash_sdui_load_assigns/3`

Use `ash_sdui_load_assigns/3` when the generated screen needs extra assigns that
do not belong in UI metadata.

```elixir
def ash_sdui_load_assigns(_mode, _params, _socket) do
  %{page_title: "Hooked Posts", demo_flag: true}
end
```

This is a good fit for:

- page title overrides
- viewer-specific display flags
- extra data needed by a custom `render/1`

## Add runtime context with `ash_sdui_context/3`

Use `ash_sdui_context/3` when view resolution should receive runtime inputs such
as audience, actor, or tenant.

```elixir
def ash_sdui_context(_params, _session, _socket) do
  %{audience: :staff}
end
```

This keeps runtime context explicit without hard-coding presentation branches
inside the UI metadata itself.

## Transform generated form params before save

Use `ash_sdui_transform_form_params/3` when the generated form needs additional
derived values.

```elixir
def ash_sdui_transform_form_params(:new, params, socket) do
  demo_user = socket.assigns.demo_user

  %{
    "title" => Map.get(params, "title", ""),
    "body" => Map.get(params, "body", "")
  }
  |> maybe_put("author_id", demo_user && to_string(demo_user.id))
  |> maybe_put(
    "published_at",
    if(Map.get(params, "publish") == "true", do: DateTime.to_iso8601(DateTime.utc_now()))
  )
end
```

Use this hook when generated form fields are not the whole save payload.

## Navigate or flash after a generated save

Use `ash_sdui_after_save/2` when the generated save should end with custom
navigation or messaging.

```elixir
def ash_sdui_after_save(record, socket) do
  socket
  |> Phoenix.LiveView.put_flash(:info, "Post created!")
  |> Phoenix.LiveView.push_navigate(to: "/posts/#{record.id}")
end
```

This keeps the generated save path but gives you control over the final user
flow.

## Use `layout: :sdui` when generated data needs a custom page shell

Set `layout: :sdui` on a view when metadata should still drive the screen, but a
recipe should shape the final layout tree.

```elixir
view :index,
  recipe: :editorial_posts,
  read_action: :read,
  layout: :sdui,
  title: "AshSDUI Journal"
```

Use this when:

- the data path should stay generated
- the stock collection, detail, or form shell is too limited
- a recipe can express the page shape cleanly

For recipe-specific work, continue with
[How to Use `layout: :sdui` Recipes](use_layout_sdui_recipes.md).
