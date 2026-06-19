# How to Use `layout: :sdui` Recipes

Use this guide when a screen should stay metadata-driven, but the stock
generated collection, detail, or form shell is not the right page structure.

For the architectural context, see
[Authoring Model](../explanation/authoring_model.md).

## Mark the view as `layout: :sdui`

Attach a recipe and `layout: :sdui` to the generated view.

```elixir
view :index,
  recipe: :editorial_posts,
  read_action: :read,
  layout: :sdui,
  title: "AshSDUI Journal"
```

This keeps the data path generated while moving the final page shell into a
recipe-built layout tree.

## Shape the screen in an app recipe

Implement `AshSDUI.LayoutRecipe` when the generated view needs an app-specific
layout tree.

```elixir
defmodule MyApp.UI.Recipes.EditorialPosts do
  @behaviour AshSDUI.LayoutRecipe

  alias AshSDUI.Layout.Builder

  def to_layout(view, opts) do
    records = Keyword.get(opts, :records, [])

    Builder.node("EditorialPostsPage@v1",
      id: "editorial-posts-page",
      static_props: %{
        title: view.assigns[:title] || "AshSDUI Journal",
        posts: Enum.map(records, &serialize_post/1)
      }
    )
  end
end
```

Use the recipe for page shape and shell props. Leave labels, widgets, and
action intent in the UI metadata when possible.

## Pass targeted recipe overrides

Use `ash_sdui_view_opts/4` when the recipe should stay the same but specific
copy or props should change.

```elixir
def ash_sdui_view_opts(_mode, _params, _session, _socket) do
  [
    recipe_overrides: [
      title: "Editorial Posts",
      empty_state: [
        title: "No posts yet",
        body: "Create the first story to populate the feed."
      ]
    ]
  ]
end
```

Use this instead of inventing a second app-specific DSL for recipe copy.

## Use this guide for

- generated screens with a custom layout shell
- app-side editorial or dashboard recipes
- metadata-first screens that need more than the stock page structure

For code-authored or runtime-built layout trees outside generated views,
continue with [How to Build Nested Layouts](build_nested_layouts.md).
