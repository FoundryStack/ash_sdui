# How to Use Queries and Filters in Generated Views

Use this guide when a generated collection screen should support search, sort,
filters, or default query behavior.

For the runtime model behind query state, see
[Runtime Model](../explanation/runtime_model.md).

## Define a `ui_query`

Attach a named query to the UI module.

```elixir
ui_query :default,
  search: [:title, :body],
  sort: [:title, :published_at],
  filters: [:title],
  default_sort: [published_at: :desc],
  default_limit: 10
```

This describes the query surface the generated view should support.

## Attach the query to the view and binding

Point the generated collection view and its collection binding at the query.

```elixir
view :index,
  recipe: :editorial_blog,
  read_action: :read,
  layout: :sdui,
  title: "AshSDUI Journal",
  query: :default

ui_binding :collection,
  source: {:resource, MyApp.Blog.Post},
  many?: true,
  query: :default
```

This keeps query behavior declarative instead of pushing it down into ad hoc
LiveView event handling.

## Customize query-driven presentation

Use `ash_sdui_view_opts/4` when a generated collection screen should change copy
or field labels while still honoring query params.

```elixir
def ash_sdui_view_opts(_mode, _params, _session, _socket) do
  [
    recipe_overrides: [
      title: "Generated Post Index",
      fields: %{
        title: %{label: "Headline"},
        published_at: %{label: "Published"}
      }
    ]
  ]
end
```

## Drive query scenarios in Storybook

Use Storybook params when you want to preview generated query state.

```elixir
use AshSDUI.Storybook,
  ui: MyApp.UI.PostUI,
  view: :index,
  params: %{"search" => "Storybook", "sort" => "-published_at", "offset" => "10"}
```

This is useful for proving search and sort behavior visually without creating a
separate mock tree.

## Use this guide for

- search over named fields
- sort controls
- filterable generated collections
- default sort and default page size

For live-updating collection bindings instead of query-driven resource reads,
continue with [How to Add Live Bindings](add_live_bindings.md).
