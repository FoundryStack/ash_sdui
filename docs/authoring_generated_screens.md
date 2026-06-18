# Authoring Generated Views

This is the preferred path when a view can stay metadata-driven.

Start with `AshSDUI.LiveResource`, add `view`, `ui_field`, and `ui_intent`
metadata to the UI module, and use `ash_sdui_view_opts/4` for small
presentation customizations.

The generated runtime is centered on one contract:

- `view`
- `bindings`
- `state`
- `context`

Built-in components, custom recipes, `layout: :sdui`, and storybook demos all
share that same shape now, so custom UI can plug in without separate adapter
layers.

See [docs/runtime_model.md](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/docs/runtime_model.md)
for the detailed lifecycle and node-scoped runtime contract.

## The ladder

Prefer these layers in order:

1. `use AshSDUI.LiveResource`
2. `view/2`, `ui_field/2`, `ui_intent/2`, `ui_query/2`, and `ui_binding/2`
3. `ash_sdui_view_opts/4`
4. `recipe_overrides`
5. a custom recipe
6. a custom `render/1` or full custom LiveView

## Smallest generated example

```elixir
defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :index,
    domain: MyApp.Blog

  def ash_sdui_view_opts(_mode, _params, _session, _socket) do
    [
      recipe: :collection,
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

## When to use `layout: :sdui`

Set `layout: :sdui` on a view when the view should still be generated from
metadata, but the final page structure should come from a recipe-built layout
tree instead of the stock LiveResource fallback renderer.

That path looks like this:

1. `AshSDUI.View.resolve/3` builds the view struct
2. `AshSDUI.LiveResource` sees `view.assigns.layout == :sdui`
3. `AshSDUI.View.to_layout/2` calls the selected recipe
4. the resulting layout tree is converted and rendered through `SDUIRoot`

Use this when:

- you want a view to stay metadata-first
- the built-in form/detail/collection rendering is close, but not enough
- a custom recipe can express the page shape cleanly

## Runtime state available to generated views

Generated screens now share more than fields and actions.

`state` can carry:

- query state
- selected IDs
- loading flags
- refresh metadata
- workflow state
- extra runtime assigns

That means a generated view can gradually become more interactive without
needing a brand-new screen architecture.

## Binding authoring

Use `ui_binding` when a screen needs named data sources beyond the stock
collection/detail assumptions.

Current source families include:

- `{:resource, resource}`
- `{:relationship, relationship}`
- `{:assign, key}`
- `{:context, key}`
- `{:runtime, key}`
- `{:selection}`
- `{:subject}`
- `{:poll, source, interval: ms}`
- `{:pubsub, topic, ...}`
- `{:stream, source, ...}`

Current refresh modes include:

- `:manual`
- `:params`
- `:subscription`
- `{:interval, ms}`

Current update strategies include:

- `:replace`
- `:append`
- `:prepend`
- `:merge`
- `:remove`

Generated views do not need to use all of that at once. The point is that the
metadata path now has room for live collections and refreshable runtime panels,
not only static CRUD.

## What belongs in `recipe_overrides`

Use `recipe_overrides` for presentational decisions that should stay easy to
author and easy to diff:

- page title
- empty-state title/body
- field label, widget, visibility, and order tweaks
- intent label, placement, or visibility tweaks
- recipe shell props such as toolbar/content classes

Keep business behavior out of `recipe_overrides`. If a view needs custom data
loading, event flow, or deeply custom component coordination, step up to a
custom recipe or a custom LiveView.

## Intent authoring

`ui_intent` is now broader than button labels and placements.

Supported target families include:

- `{:navigate, path}`
- `{:patch, path}`
- `{:event, event}`
- `{:ash_action, action}`
- `{:refresh, binding_or_view}`
- `{:select, operation}`
- `{:workflow, event}`
- `{:custom, module, function}`

Supported behavioral metadata includes:

- `visible_when`
- `enabled_when`
- `loading_when`
- `refreshes`

`loading_when` should currently be treated as declarative render metadata, not
as a promise of fully automatic async lifecycle management.

## Storybook for generated views

Use `AshSDUI.Storybook` with `ui:` and `view:` when you want the demo surface
to exercise the generated runtime instead of a hand-authored mock tree.

```elixir
defmodule MyAppWeb.Storybook.Posts do
  use AshSDUI.Storybook,
    ui: MyApp.UI.PostUI,
    view: :index,
    bindings: %{collection: [%{id: "1", title: "Hello"}]}
end
```

That path resolves the view, passes bindings into the recipe, and renders the
tree through `AshSDUI.Components.SDUIRoot`.
