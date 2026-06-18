# AshSDUI Roadmap and Status

This document is a status-aware roadmap, not a bootstrap plan.

The early scaffolding work is done. The package, demo app, Storybook, runtime
contracts, and regression tests already exist. Current work should treat this
document as a ledger of what has shipped, what remains intentionally deferred,
and what future slices should build on.

## History

AshSDUI has moved through three major implementation phases:

1. Foundation
   - component registry
   - layout builder and renderer
   - persisted layouts through `AshSDUI.Layout` and `AshSDUI.UINode`
   - generated view metadata via `view`, `ui_field`, `ui_query`,
     `ui_binding`, and `ui_intent`
2. Runtime expansion
   - `AshSDUI.View` as the normalized UI contract
   - `AshSDUI.LiveResource` as the generic host
   - shared runtime values: `view`, `bindings`, `state`, `context`
   - richer intent metadata and refresh-aware runtime state
3. Live and hybrid runtime
   - streaming and PubSub-backed bindings
   - selection state
   - workflow state
   - generic live-aware components
   - hybrid layout metadata with node `binding`, `refresh`, `variant`,
     and `state_key`

## Implemented

### Runtime model

- `AshSDUI.View` resolves metadata and runtime state into one inspectable struct
- `AshSDUI.View.State` carries query, params, selection, loading, refresh,
  workflow, and extra assigns
- `AshSDUI.Binding` supports snapshot, poll, PubSub, and stream-style sources
- `AshSDUI.Intent` normalizes built-in and custom targets into command envelopes
- `AshSDUI.LiveResource` owns loading, refresh, subscriptions, selection,
  workflow, and generated event handling

### Layout model

- code-authored layouts through `AshSDUI.Layout.Builder`
- persisted layouts through `AshSDUI.Layout.save/3`, `fetch/2`, and `publish/2`
- ephemeral runtime layouts through `AshSDUI.LiveScreen.assign_layout/3`
- node-level runtime metadata:
  - `binding`
  - `refresh`
  - `variant`
  - `state_key`

### Demo proof surface

The following routes and Storybook leaves are part of the accepted proof map:

- `/posts/generated`
- `/live/feed`
- `/live/metrics`
- `/live/selection`
- `/live/workflow`
- `/live/hybrid`
- layout persistence and management demos

See `/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/README.md`
for the current coverage matrix.

## Deferred or Partial

These areas are intentionally not described as complete:

### Query extensions

Current support:

- search
- field filters
- sorting
- default sort
- offset pagination

Future work:

- range filters
- cursor pagination
- richer grouped filters
- stronger multi-sort ergonomics

### Async lifecycle

Current support:

- declarative `loading_when`
- runtime `state.loading`

Still partial:

- automatic async intent lifecycle orchestration
- uniform loading semantics across all intent classes

### Workflow DSL

Current support:

- view/workflow metadata
- runtime workflow state
- workflow-targeted intents

Still deferred:

- a dedicated `ui_workflow` DSL

### Selection DSL

Current support:

- runtime `state.selected`
- selection-oriented intents
- selected-record hydration conveniences in `LiveResource`

Still deferred:

- a dedicated `ui_selection` DSL

### Fine-grained rendering guarantees

Node metadata is available to components now, but AshSDUI does not yet promise:

- separate LiveView processes per node
- full node-level render isolation
- a partial-process rendering model

## Active Direction

Near-term work should focus on stabilization and clarity rather than another
large redesign:

1. keep the runtime contract stable and well documented
2. tighten tests around documented behavior
3. extend query and async semantics incrementally
4. add new generic live-aware components only when they prove reusable runtime
   primitives

## Source of Truth

For current behavior, start with:

1. `/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/README.md`
2. `/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/docs/spec.md`
3. `/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/docs/runtime_model.md`

Treat this roadmap and older greenfield planning language as status context, not
as the main behavioral spec.
