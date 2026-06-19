# AshSDUI

AshSDUI is a server-driven UI layer for Phoenix LiveView applications backed by
[Ash](https://hexdocs.pm/ash). It combines metadata-driven generated screens,
persisted or code-authored layout trees, and a shared runtime contract for
building Ash-aware LiveView interfaces.

## Why AshSDUI

AshSDUI is useful when you want more than scaffolded CRUD, but you still want a
declarative path that stays close to your Ash resource model.

- It separates metadata, view resolution, recipes, and render trees into clear layers.
- It gives humans and agents a smaller authoring surface through standalone UI modules.
- It keeps generated screens, custom layouts, and live runtime components on one contract.
- It can grow from generated pages into product UI without forcing a rewrite of the whole stack.

## Features

- Metadata-driven generated screens through `AshSDUI.LiveResource`
- A shared runtime contract for generated views and SDUI layouts: `view`, `bindings`, `state`, and `context`
- Layout authoring with `AshSDUI.Layout.Builder` plus persisted layouts through `AshSDUI.Layout`
- Ephemeral runtime layouts through `AshSDUI.LiveScreen.assign_layout/3`
- Metadata-driven forms and actions from `ui_field`, `ui_nested_form`, `ui_attribute`, and `ui_intent`
- Live bindings with poll, PubSub, and stream-style update paths
- Reusable runtime-aware components for lists, metrics, status, activity, and selection
- Storybook and demo surfaces that exercise the generated and layout-rendered paths
- ETS-backed layout caching with automatic invalidation for stored-node changes

## Installation

```elixir
def deps do
  [
    {:ash_sdui, "~> 0.1"},
    {:phoenix_live_view, "~> 1"}
  ]
end
```

The built-in `AshSDUI.UINode` uses ETS storage and is suitable for tests, demos,
and local prototypes. Production applications that need database-backed layouts
should provide a compatible Ash resource and pass it as `node_resource:`.

## Quickstart

The easiest end-to-end path is:

1. define UI metadata for an Ash resource
2. mount it with `AshSDUI.LiveResource`
3. expose the generated screens from your router

```elixir
defmodule MyApp.UI.PostUI do
  use AshSDUI.Resource.Standalone

  sdui do
    for_resource MyApp.Blog.Post
    view :index, recipe: :collection, read_action: :read
    view :new, recipe: :form, action: :create

    ui_field :title, label: "Headline", widget: :text_input, order: 0
    ui_field :body, label: "Body", widget: :textarea, order: 1
    ui_field :author_id, label: "Author", order: 2

    ui_intent :create,
      label: "Write post",
      target: {:navigate, "/posts/new"}
  end
end

defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :index,
    domain: MyApp.Blog
end

defmodule MyAppWeb.PostNewLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :new,
    domain: MyApp.Blog
end
```

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  live "/posts", PostsLive
  live "/posts/new", PostNewLive
end
```

This gives you:

- a generated collection screen at `/posts`
- a generated form screen at `/posts/new`
- form widgets driven by `ui_field` metadata
- action labels and targets driven by `ui_intent` metadata
- room to add relationship-aware widgets such as generated selects without
  replacing the generated host

Prefer this path before stepping up to custom recipes or hand-authored
LiveViews.

If a generated form should let the user pick an existing related record, keep
that in metadata too:

```elixir
ui_field :author_id,
  label: "Author",
  order: 2
```

When `:author_id` matches a `belongs_to` relationship source attribute such as
`author`, the generated form now renders a select automatically and loads the
options from the related resource's read action. For relationship arguments such
as `:tag_ids`, use `relationship:` and let the form render a multiselect.

If the form should create or edit related records inline, model that
separately with `ui_nested_form`:

```elixir
create :create do
  accept [:title]
  argument :comments, {:array, :map}, allow_nil?: true

  change manage_relationship(:comments, :comments, type: :direct_control)
end

sdui do
  ui_field :title, label: "Headline", order: 1
  ui_nested_form :comments, label: "Comments", order: 2
end
```

That keeps relationship picking on `ui_field` and inline related-record editing
on `ui_nested_form`.

For layout authoring, prefer:

- `AshSDUI.Layout.Builder.resource/2` and `resources/3`
- `AshSDUI.Layout.fetch/2`, `register/2`, `save/3`, and `publish/2`
- `AshSDUI.LiveScreen.assign_layout/3`

Avoid new code that depends on `AshSDUI.Layout.Persistence` directly.

## Documentation

### Tutorial

- [Build Your First Generated Screen](docs/tutorials/build_your_first_generated_screen.md)

### How-to Guides

- [Author Generated Screens](docs/how-to/author_generated_screens.md)
- [Customize Generated Forms](docs/how-to/customize_generated_forms.md)
- [Use Queries and Filters](docs/how-to/use_queries_and_filters.md)
- [Add Live Bindings](docs/how-to/add_live_bindings.md)
- [Render Generated Views in Storybook](docs/how-to/render_generated_views_in_storybook.md)
- [Use `layout: :sdui` Recipes](docs/how-to/use_layout_sdui_recipes.md)
- [Build Nested Layouts](docs/how-to/build_nested_layouts.md)
- [Work with SDUI Layouts](docs/how-to/work_with_sdui_layouts.md)

### Reference

- [Public API Map](docs/reference/public_api.md)
- [Runtime Contract](docs/reference/runtime_contract.md)

### Explanation

- [Runtime Model](docs/explanation/runtime_model.md)
- [Authoring Model](docs/explanation/authoring_model.md)
- [Demo and Storybook](docs/explanation/demo_and_storybook.md)

## Demo and proof surfaces

`examples/sdui_demo` is the public proof surface for promoted features. It maps
generated screens, runtime bindings, hybrid layouts, and persisted layouts to a
demo route, Storybook surface, and regression test.

Storybook is part of that proof surface. Prefer generated-view and reusable
building-block stories over raw low-level component stories when documenting or
reviewing package behavior.

See [examples/sdui_demo/README.md](examples/sdui_demo/README.md) for the current
coverage matrix.
