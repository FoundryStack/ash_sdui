# Authoring generated screens

This is the preferred path when a screen can stay metadata-driven.

Start with `AshSDUI.LiveResource`, add SDUI metadata to the UI module, and use
`ash_sdui_screen_opts/4` for the small customizations that would otherwise push
you into a hand-written LiveView.

## The ladder

Prefer these layers in order:

1. `use AshSDUI.LiveResource`
2. `screen/2`, `ui_attribute/2`, and `ui_action/2` metadata
3. `ash_sdui_screen_opts/4`
4. `recipe_overrides`
5. a custom recipe
6. a custom `render/1` or full custom LiveView

That keeps the common path short for both humans and LLM agents.

## Smallest generated example

```elixir
defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    resource: MyApp.UI.PostUI,
    screen: :index,
    domain: MyApp.Blog

  def ash_sdui_screen_opts(_mode, _params, _session, _socket) do
    [
      recipe: :collection,
      recipe_overrides: [
        title: "Editorial Posts",
        empty_state: [
          title: "No posts yet",
          body: "Create the first story to populate the feed."
        ],
        fields: %{
          title: %{label: "Headline"}
        },
        actions: %{
          create: %{label: "Compose Post"}
        }
      ]
    ]
  end
end
```

## When to use `layout: :sdui`

Set `layout: :sdui` on a screen when the screen should still be generated from
metadata, but the final page structure should come from a recipe-built layout
tree instead of the stock LiveResource fallback renderer.

That path looks like this:

1. `AshSDUI.Screen.resolve/3` builds the screen struct
2. `AshSDUI.LiveResource` sees `screen.assigns.layout == :sdui`
3. `AshSDUI.Screen.to_layout/2` calls the selected recipe
4. the resulting layout tree is converted and rendered through `SDUIRoot`

Use this when:

- you want a screen to stay metadata-first
- the built-in form/detail/collection rendering is close, but not enough
- a custom recipe can express the page shape cleanly

Do not use it when a LiveView is building a one-off layout from current records
or state at runtime. That is what `AshSDUI.LiveScreen.assign_layout/3` is for.

## What belongs in `recipe_overrides`

Use `recipe_overrides` for presentational decisions that should stay easy to
author and easy to diff:

- page title
- empty-state title/body
- field label, widget, visibility, and order tweaks
- action label, placement, or visibility tweaks
- recipe shell props such as toolbar/content classes

Keep business behavior out of `recipe_overrides`. If a screen needs custom data
loading, event flow, or deeply custom component coordination, step up to a
custom recipe or a custom LiveView.

## Signals that the abstraction is slipping

It is time to leave the generated path when one of these becomes true:

- `ash_sdui_screen_opts/4` starts assembling data instead of shaping metadata
- the same screen override logic is repeated across multiple LiveViews
- the screen needs runtime layout switching from current assigns
- custom event flow becomes the main concern instead of presentation

At that point, move the shaping logic into a recipe or use
`AshSDUI.LiveScreen.assign_layout/3` for an explicit runtime layout.
