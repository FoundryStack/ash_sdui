# AGENTS.md — `packages/ash_sdui`

This package exists to make SDUI authoring smaller, more declarative, and safer for both humans and agents.

## Preferred authoring path

- Prefer `AshSDUI.Layout.Builder.resource/2` and `AshSDUI.Layout.Builder.resources/3` over manual `%AshSDUI.Layout.Node{}` structs.
- Prefer `AshSDUI.Layout.fetch/2`, `register/2`, `save/3`, and `publish/2` as the single public layout API.
- Prefer `AshSDUI.LiveScreen.assign_layout/3` when a LiveView rebuilds ephemeral layouts.
- Prefer `AshSDUI.Form.fields/2` plus a shared form component over hand-maintained field lists.
- Prefer `ui_action` and `ui_attribute` metadata as the source of truth for labels, order, and widgets.
- Prefer adding `widget:` to `ui_attribute` when a generated form should use `:textarea`, `:email`, or another non-default input.
- For production database layout storage, pass a compatible custom Ash resource as `node_resource:` instead of trying to reconfigure the built-in `AshSDUI.UINode`.

## Avoid

- Do not duplicate action labels or button intent in multiple places when the resource metadata already declares them.
- Do not hand-assemble `subject_resource` strings when the UI module already knows `for_resource`.
- Do not create one-off LiveView helpers for cache eviction and tree refresh when `AshSDUI.LiveScreen` can own it.
- Do not call `AshSDUI.Layout.Persistence` in new code; it only exists for compatibility.

## Demo expectations

- Storybook should show the simplified building blocks, not only the lowest-level raw components.
- Tests should exercise metadata-driven forms/actions so regressions are caught where the abstraction lives.
