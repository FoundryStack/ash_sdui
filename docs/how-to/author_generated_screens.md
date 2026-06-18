# How to Author Generated Screens

Use this guide when a screen should stay metadata-driven and you want to adjust
its behavior or presentation without taking over the whole LiveView.

For the runtime concepts behind these tasks, see
[Runtime Model](../explanation/runtime_model.md). For the API surface, see
[Public API Map](../reference/public_api.md).

## Keep a screen on `AshSDUI.LiveResource`

Start with `AshSDUI.LiveResource` when the screen still fits the generated
collection, detail, or form path.

```elixir
defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :index,
    domain: MyApp.Blog
end
```

Stay on this path when the work is mostly:

- field and intent metadata
- query and binding declarations
- presentational recipe overrides
- a generated form backed by `AshSDUI.Form.fields/2`

Step up to a custom recipe or custom LiveView only when screen coordination or
data flow no longer fits the generated host.

## Override generated presentation with `ash_sdui_view_opts/4`

Use `ash_sdui_view_opts/4` for labels, copy, and recipe-level presentation.

```elixir
defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :index,
    domain: MyApp.Blog

  def ash_sdui_view_opts(_mode, _params, _session, _socket) do
    [
      recipe_overrides: [
        title: "Editorial Posts",
        empty_state: [
          title: "No posts yet",
          body: "Create the first story to populate the feed."
        ],
        fields: %{title: %{label: "Headline"}},
        intents: %{create: %{label: "Compose Post"}}
      ]
    ]
  end
end
```

Use `recipe_overrides` for presentational choices that should stay easy to
author and easy to diff.

## Drive forms from metadata

Keep generated forms on shared metadata instead of hand-maintained field lists.

```elixir
sdui do
  view :new, recipe: :form, action: :create
  view :edit, recipe: :form, action: :update

  ui_field :title, label: "Headline", widget: :text_input
  ui_field :body, label: "Body", widget: :textarea
  ui_field :email, label: "Editor Email", widget: :email
end
```

Use `widget:` when a generated form should render `:textarea`, `:email`, or
another non-default input. Let `AshSDUI.Form.fields/2` and the shared form
component consume that metadata.

## Keep action labels and behavior in metadata

Declare action labels and targets with resource metadata instead of duplicating
button intent in multiple places.

```elixir
sdui do
  ui_intent :publish,
    label: "Publish story",
    target: {:ash_action, :publish},
    refreshes: [:subject]
end
```

Use `ui_intent` and `ui_field` as the source of truth. Reserve
`ash_sdui_view_opts/4` for targeted overrides, not duplicate declarations.

## Use `layout: :sdui` when a generated view needs a custom page shell

Set `layout: :sdui` on a view when metadata should still drive the screen, but
the final page structure should come from a recipe-built layout tree.

```elixir
view :index,
  recipe: :editorial_posts,
  layout: :sdui,
  title: "AshSDUI Journal"
```

Use this when the screen is still generated, but the stock collection, detail,
or form shell is not the right presentation.

## Use Storybook for generated-view proof

Prefer `AshSDUI.Storybook` with `ui:` and `view:` when the story should prove
generated behavior instead of a hand-authored mock tree.

```elixir
defmodule MyAppWeb.Storybook.Posts do
  use AshSDUI.Storybook,
    ui: MyApp.UI.PostUI,
    view: :index,
    bindings: %{collection: [%{id: "1", title: "Hello"}]}
end
```

Use Storybook here to show:

- generated view composition
- metadata-driven labels and widgets
- reusable runtime-aware building blocks

For why this proof surface matters, see
[Demo and Storybook](../explanation/demo_and_storybook.md).
