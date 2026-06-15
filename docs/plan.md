# Plan: Implement AshSDUI Library

> Historical note: this bootstrap plan is effectively complete. The package now
> exists, tests pass, Storybook support is available through
> `AshSDUI.Storybook`, and the generated UI path is centered on
> `AshSDUI.View`, `ui_binding`, `ui_query`, `ui_field`, and `ui_intent`.
> Current work should treat this document as historical context, not as the
> active source of truth for public APIs.

## Context

Building a Server-Driven UI library from scratch based on the spec at `packages/ash_sdui/docs/spec.md`. The package directory currently contains only the spec — no code. The `examples/` directory doesn't exist yet. Approach: tests → implementation → storybook → example app.

---

## Phase 1: Package Scaffold (`packages/ash_sdui`)

Create the Mix package skeleton:

```
packages/ash_sdui/
├── mix.exs
├── lib/
│   └── ash_sdui/
└── test/
    └── ash_sdui/
```

**`mix.exs` deps:**

- `ash`, `ash_postgres`, `phoenix_live_view`, `phoenix`, `ash_paper_trail`
- dev/test: `phoenix_storybook`, `ex_unit`

---

## Phase 2: Tests First

### `test/ash_sdui/component_test.exs`

- `use AshSDUI.Component, fragment: "..."` registers the module
- Component name is auto-derived from module name + version suffix
- Registry lookup returns `{module, fragment, inferred_subject_types}`
- Invalid fragment raises compile error

### `test/ash_sdui/registry_test.exs`

- `AshSDUI.Registry.lookup("UserProfile.Header@v1")` returns registered struct
- `AshSDUI.Registry.all()` returns all registered components
- Missing key returns `{:error, :not_found}`

### `test/ash_sdui/layout_test.exs`

- `sdui_layout` DSL compiles without error
- `AshSDUI.Layout.get("player-dashboard")` returns the tree struct
- Nested `node` blocks produce correct parent-child relationships
- `region:` and `order:` options are preserved

### `test/ash_sdui/ui_node_test.exs`

- UINode resource has expected attributes (component_name, static_props, subject_resource, subject_id, region, order, status)
- `component_name` format constraint rejects `"Bad"`, accepts `"Foo.Bar@v1"`
- `status` defaults to `:draft`, accepts `:published`, `:archived`

### `test/ash_sdui/rendering_test.exs`

- Given a code-based layout tree, `AshSDUI.Renderer.to_tree/1` returns nested struct
- DB-first / code-fallback logic: DB hit returns DB records; DB miss calls layout registry

---

## Phase 3: Core Implementation

### `lib/ash_sdui.ex`

Main entry point. `use AshSDUI, lookup: {:from_params, :name}` macro that injects `mount/3` into a LiveView with unified lookup logic (DB-first → code fallback).

### `lib/ash_sdui/component.ex`

`use AshSDUI.Component, fragment: "..."` macro:

1. Parses GQL fragment at compile time to infer `subject_type` (the `on <Type>` clause)
2. Derives component name from module alias (e.g. `MyApp.Components.UserProfile.Header` → `"UserProfile.Header"`) + requires explicit `@version` or defaults to `v1`
3. Calls `AshSDUI.Registry.register/3` in `@on_load` / module attribute

### `lib/ash_sdui/registry.ex`

- Stores component map in `:persistent_term` under key `{AshSDUI.Registry, :components}`
- `register(name, module, meta)` — called at compile time via module attribute hooks
- `lookup(name)`, `all()` public API

### `lib/ash_sdui/layout.ex`

Spark DSL extension providing `sdui_layout` block with nested `node` entities. Stores parsed layout trees in `:persistent_term` under `{AshSDUI.Layout, :layouts}` at compile time.

DSL entities:

- `sdui_layout` — top-level section, has `name` option and nested `node` entities
- `node` — recursive entity with options: `component`, `bind_subject`, `region`, `order`

### `lib/ash_sdui/ui_node.ex`

Ash Resource (no data layer specified — users configure this). Attributes per spec + `status` field. `publish` and `revert` actions. `AshPaperTrail.Resource` extension.

### `lib/ash_sdui/calculations/resolve_subject.ex`

Ash calculation that resolves `{subject_resource, subject_id}` → Ash record using `Code.ensure_loaded` + `Ash.get`.

### `lib/ash_sdui/cache.ex`

GenServer with ETS table. Subscribes to `AshSDUI.UINode` notifier. On change: evict graph for affected root. `get(name)` / `put(name, tree)` API.

### `lib/ash_sdui/renderer.ex`

- `render_tree(root_node, assigns)` — recursive HEEx rendering via `Phoenix.LiveView.TagEngine`
- `to_tree(layout_name_or_db_records)` — normalizes both sources into `%AshSDUI.Node{}` structs

### `lib/ash_sdui/sdui_page_live.ex`

Generic LiveView provided by the library, usable as a base or directly.

_(No `render_in_storybook` wrapper needed — stories reference component modules directly via `function: &MyComponent.render/1`.)_

---

## Phase 4: Phoenix Storybook Integration

Inside the example app (`examples/sdui_demo`), configure `phoenix_storybook`:

```
priv/storybook/
└── components/
    ├── user_card.story.exs          # leaf component story
    ├── action_button.story.exs      # leaf component story
    └── two_column_layout.story.exs  # layout story — uses mock inner_block slot children
```

- Leaf component stories: `function: &UserCard.render/1`, assigns include mock `subject` struct.
- Layout stories: `function: &TwoColumnLayout.render/1`, assigns include `inner_block` slot mock with HTML strings for each named region (`:sidebar`, `:main`). This lets storybook render the layout shell without a full graph.

---

## Phase 5: Example App (`examples/sdui_demo`)

Minimal Phoenix app (no Ecto — uses in-memory/ETS data layer or static fixtures).

### Structure

```
examples/sdui_demo/
├── mix.exs                  (dep on ash_sdui via path)
├── lib/
│   ├── sdui_demo/
│   │   ├── accounts/user.ex       (Ash Resource, AshETS data layer)
│   │   └── ui/
│   │       └── layouts/default.ex  (uses AshSDUI.Layout DSL)
│   └── sdui_demo_web/
│       ├── components/
│       │   ├── user_card.ex        (use AshSDUI.Component)
│       │   └── action_button.ex    (use AshSDUI.Component)
│       ├── live/
│       │   └── demo_live.ex        (use AshSDUI, lookup: {:static, "user-dashboard"})
│       └── router.ex               (live "/", DemoLive, :index)
├── priv/storybook/
│   └── components/
│       ├── user_card.story.exs
│       └── action_button.story.exs
└── config/config.exs
```

### What it demonstrates

1. Navigate to `/` → renders code-based layout with `UserCard` component (code fallback path)
2. Storybook at `/storybook` shows isolated leaf + layout component stories
3. `AshSDUI.UINode` data layer is configured in `config.exs` (AshETS) — no wrapper resource needed in demo

> Note: `AshSDUI.UINode` is a library resource. Apps configure its data layer via config, not by redefining it.

---

## Critical Files to Create

| File                                          | Purpose                      |
| --------------------------------------------- | ---------------------------- |
| `packages/ash_sdui/mix.exs`                   | Package definition           |
| `packages/ash_sdui/lib/ash_sdui.ex`           | `use AshSDUI` macro          |
| `packages/ash_sdui/lib/ash_sdui/component.ex` | Component macro              |
| `packages/ash_sdui/lib/ash_sdui/registry.ex`  | persistent_term registry     |
| `packages/ash_sdui/lib/ash_sdui/layout.ex`    | Spark DSL extension          |
| `packages/ash_sdui/lib/ash_sdui/ui_node.ex`   | Core Ash Resource            |
| `packages/ash_sdui/lib/ash_sdui/renderer.ex`  | Rendering engine             |
| `packages/ash_sdui/lib/ash_sdui/cache.ex`     | ETS cache GenServer          |
| `packages/ash_sdui/test/ash_sdui/*_test.exs`  | Test suite                   |
| `examples/sdui_demo/mix.exs`                  | Example app                  |
| `examples/sdui_demo/lib/**`                   | Example components + layouts |
| `examples/sdui_demo/priv/storybook/**`        | Stories (leaf + layout)      |

---

## Verification

1. `cd packages/ash_sdui && mix test` — all tests pass
2. `cd examples/sdui_demo && mix phx.server` — server starts, `/p/user-dashboard` renders
3. `http://localhost:4000/storybook` — storybook shows `UserCard` and `ActionButton` stories
4. Modify a `UINode` record (via IEx) → cache evicts → next render reflects the change
