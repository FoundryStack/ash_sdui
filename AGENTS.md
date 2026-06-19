# AGENTS.md - `packages/ash_sdui`

This package exists to make SDUI authoring smaller, more declarative, and safer
for both humans and agents. Treat Ash resource metadata, the shared runtime
contract, and the demo proof surface as the center of gravity.

## Preferred authoring ladder

Prefer the smallest layer that can honestly describe the screen:

1. `AshSDUI.LiveResource`
2. resource metadata: `view`, `ui_field`, `ui_nested_form`, `ui_intent`, `ui_query`, and `ui_binding`
3. `ash_sdui_view_opts/4` and `recipe_overrides`
4. custom recipes with `layout: :sdui`
5. custom `render/1`
6. full custom LiveViews

Stay generated while the complexity is mostly fields, forms, actions, queries,
bindings, or reusable layout structure. Move to raw LiveView when the screen is
mostly bespoke event coordination or when the branching is clearer as explicit
LiveView code.

## Preferred APIs

- Prefer `AshSDUI.LiveResource` for generated and semi-generated resource screens.
- Prefer `AshSDUI.Layout.Builder.resource/2` and `AshSDUI.Layout.Builder.resources/3` over manual `%AshSDUI.Layout.Node{}` structs.
- Prefer `AshSDUI.Layout.fetch/2`, `register/2`, `save/3`, and `publish/2` as the single public layout API.
- Prefer `AshSDUI.LiveScreen.assign_layout/3` when a LiveView rebuilds ephemeral layouts from records, mode switches, runtime state, or audience-specific decisions.
- Prefer `AshSDUI.Form.fields/2` and `AshSDUI.Form.nested_forms/2` plus shared form components over hand-maintained field lists.
- Prefer `ui_field`, `ui_nested_form`, and `ui_intent` metadata as the source of truth for labels, order, widgets, action labels, button style, and target behavior.
- Prefer adding `widget:` to `ui_field` when a generated form should use `:textarea`, `:email`, `:select`, `:multiselect`, or another non-default input.
- Prefer `ui_query` and `ui_binding` for declarative query and live data behavior before adding custom LiveView loading code.
- For production database layout storage, pass a compatible custom Ash resource as `node_resource:` instead of trying to reconfigure the built-in `AshSDUI.UINode`.

## Server-driven UI

AshSDUI is a server-driven UI layer, but it should not become an opaque rules
engine. Put each decision at the layer that owns it.

- Use `ash_sdui_context/3` for actor, tenant, locale, audience, device, and arbitrary runtime assigns.
- Use `ash_sdui_view_opts/4` for runtime recipe selection, titles, copy, and `recipe_overrides`.
- Use `variant_resolvers` when context should transform the resolved `AshSDUI.View`.
- Use `layout: :sdui` recipes when the server must choose component composition from resolved view data, bindings, records, or context.
- Use `AshSDUI.LiveScreen.assign_layout/3` when layout trees are rebuilt at runtime and do not need persistence.
- Use node metadata such as `binding`, `refresh`, `variant`, and `state_key` for focused component behavior.
- Use `visible_when`, `enabled_when`, `loading_when`, and `refreshes` for simple intent behavior.
- Put complex audience, authorization, workflow, or layout branching in ordinary Elixir: `ash_sdui_view_opts/4`, a variant resolver, a recipe module, or the LiveView that calls `assign_layout/3`.

## Avoid

- Do not duplicate field labels, action labels, button style, or intent targets when resource metadata already declares them.
- Do not hand-assemble `subject_resource` strings when the UI module already knows `for_resource`.
- Do not create one-off LiveView helpers for cache eviction and tree refresh when `AshSDUI.LiveScreen` can own it.
- Do not call `AshSDUI.Layout.Persistence` in new code; it only exists for compatibility.
- Do not hide complex business rules inside component props when a named recipe, context function, or variant resolver would make the decision easier to inspect.
- Do not force a screen into SDUI when raw LiveView is the clearer tool for a one-off, highly interactive flow.

## Demo and documentation expectations

- Storybook should show simplified building blocks and generated-view surfaces, not only lowest-level raw components.
- Tests should exercise metadata-driven forms, actions, queries, live bindings, and layout-rendered paths so regressions are caught where the abstraction lives.
- Public features should have a demo route, Storybook coverage when visual isolation helps, and a regression test.
- Update `examples/sdui_demo/README.md` when adding or promoting a proof surface.
- Update docs when changing the preferred authoring path, runtime contract, public layout API, or server-driven decision points.

## Useful docs

- Start with `README.md` for package positioning and the quickstart.
- Use `docs/reference/public_api.md` for the supported public surface.
- Use `docs/reference/runtime_contract.md` for `view`, `bindings`, `state`, `context`, and node runtime metadata.
- Use `docs/explanation/authoring_model.md` for the authoring ladder.
- Use `docs/explanation/when_to_use_ash_sdui.md` for adoption boundaries, server-driven UI guidance, and LOC tradeoffs.
