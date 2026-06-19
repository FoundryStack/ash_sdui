# How to Render Generated Views in Storybook

Use this guide when you want Storybook to prove generated-view behavior instead
of only showcasing low-level components.

For the role Storybook plays in the package, see
[Demo and Storybook](../explanation/demo_and_storybook.md).

## Build a generated story from UI metadata

Use `AshSDUI.Storybook` with `ui:` and `view:`.

```elixir
defmodule MyAppWeb.Storybook.Posts do
  use AshSDUI.Storybook,
    ui: MyApp.UI.PostUI,
    view: :index,
    bindings: %{collection: [%{id: "1", title: "Hello"}]}
end
```

This resolves the view, passes bindings into the recipe, and renders through the
same `SDUIRoot` path used by generated runtime screens.

## Preview a generated form

Use a form view when the story should prove widget and field metadata.

```elixir
defmodule MyAppWeb.Storybook.PostUINew do
  use AshSDUI.Storybook,
    ui: MyApp.UI.PostUI,
    view: :new
end
```

This is a good fit for generated form stories that need to confirm
`ui_field`-driven widgets or field components.

## Preview filtered query state

Pass `params:` when the story should render a generated query scenario.

```elixir
use AshSDUI.Storybook,
  ui: MyApp.UI.PostUI,
  view: :index,
  params: %{"search" => "Storybook", "sort" => "-published_at", "offset" => "10"}
```

This is useful for proving query behavior without hand-building a separate mock
tree.

## Prefer generated stories over raw-tree demos for generated features

Use `AshSDUI.Storybook` when the feature being demonstrated is:

- generated view composition
- query state
- metadata-driven form rendering
- runtime bindings flowing through the generated path

Use lower-level component stories only when the thing being demonstrated is the
component itself.
