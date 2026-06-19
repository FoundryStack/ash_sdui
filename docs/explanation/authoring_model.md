# Authoring Model

AshSDUI prefers the smallest declarative surface that can still describe the
screen. The package is designed around an authoring ladder, not around one
mandatory abstraction.

## The preferred ladder

The first stop is usually `AshSDUI.LiveResource` with resource metadata:
`view`, `ui_field`, `ui_intent`, `ui_query`, and `ui_binding`. That path keeps
the screen close to Ash metadata and lets generated forms and actions use one
source of truth.

The next step is `ash_sdui_view_opts/4` and `recipe_overrides`, which change
presentation without discarding the generated host. After that comes a custom
recipe, which still keeps the screen metadata-first while letting the page shell
come from a layout tree. Only after those layers stop fitting should a screen
move to a custom `render/1` or a fully custom LiveView.

## Why metadata is the source of truth

The package prefers metadata because duplicated UI declarations drift. Labels,
widgets, and action intent become harder to trust when they are spread across UI
modules, form components, LiveViews, and Storybook stories.

By keeping `ui_field` and `ui_intent` authoritative, AshSDUI can drive
generated forms, actions, and proof surfaces from one place. This makes authoring
smaller and safer for humans and agents.

## The three layout paths

There are three distinct layout paths in the package.

Generated `layout: :sdui` views still start from view metadata. A recipe turns
the resolved view into a layout tree, so the screen stays generated even though
its final page shell is custom.

Ephemeral layouts are built directly in a LiveView from current records, mode
switches, or runtime assigns. `AshSDUI.LiveScreen.assign_layout/3` exists for
this case because the layout is real, but it does not need persistence.

Persisted layouts are named layout trees stored through `AshSDUI.Layout`. They
support draft and publish workflows and can later be reloaded without changing
application code.

## Why the layout API stays small

The package deliberately centers the layout API on `fetch/2`, `register/2`,
`save/3`, and `publish/2`, with `AshSDUI.Layout.Builder.resource/2` and
`resources/3` as the preferred authoring helpers. This keeps the public surface
small while still covering code-authored, ephemeral, and persisted layouts.

That is also why `AshSDUI.Layout.Persistence` is no longer the documented path.
It remains for compatibility, but it is not the abstraction the package wants
new code to learn first.
