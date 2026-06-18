# Runtime Model

This guide explains the current AshSDUI runtime in practical terms.

If you are authoring generated screens, custom recipes, or layout-rendered
components, this is the contract to build against.

## The Four Core Values

AshSDUI resolves a screen into four shared runtime values:

- `view`
- `bindings`
- `state`
- `context`

That same contract flows through:

- `AshSDUI.LiveResource`
- generated collection/detail/form screens
- `layout: :sdui` recipe trees
- ephemeral runtime layouts assigned with `AshSDUI.LiveScreen.assign_layout/3`
- Storybook demos that exercise runtime-aware components

## Lifecycle

At a high level, a generated screen works like this:

1. `AshSDUI.View.resolve/3` builds the view model
2. `AshSDUI.Binding.plan/2` normalizes bindings
3. `AshSDUI.Binding.load/2` loads snapshot values
4. `AshSDUI.LiveResource` stores runtime state and registers subscriptions
5. the screen renders either through a stock recipe or through `SDUIRoot`
6. refresh, select, workflow, query, and intent events update the runtime

## `view`

`AshSDUI.View` is the normalized UI description for a screen.

It contains:

- resource and UI module identity
- mode and selected action
- recipe selection
- field metadata
- intent metadata
- binding declarations
- query state
- generic assigns
- refresh and workflow metadata

Use the view when a component or recipe needs structural information about the
screen rather than loaded binding values.

## `bindings`

Bindings are named runtime data sources.

Examples:

- a collection loaded from `{:resource, MyApp.Post}`
- a selected record relationship
- a runtime assign from `{:assign, :record}`
- a context value from `{:context, :locale}`
- a live PubSub-driven stream

The `bindings` runtime value is a map of loaded binding names to current values.

### Binding metadata

Resolved binding structs also track:

- `source_kind`
- `refresh`
- `update_strategy`
- `status`
- `subscription`

That metadata is used by `LiveResource` and can also be surfaced to components
through `refresh_meta`.

## `state`

`AshSDUI.View.State` stores runtime-local screen state:

- `query`
- `params`
- `selected`
- `loading`
- `refresh`
- `workflow`
- `assigns`

Examples:

- selected IDs for a collection toolbar
- per-binding refresh timestamps or status
- workflow status for a staged action flow
- local ad hoc runtime values in `assigns`

## `context`

`AshSDUI.Context` carries cross-cutting runtime information such as:

- `actor`
- `tenant`
- `locale`
- `audience`
- `device`
- arbitrary `assigns`

Use context for presentation and data-loading inputs that belong to the current
viewer or execution environment, not to the screen structure itself.

## Node-Scoped Runtime in `SDUIRoot`

When a view is rendered through an SDUI layout tree, each node can opt into a
slice of the runtime with:

- `binding`
- `refresh`
- `variant`
- `state_key`

`AshSDUI.Components.SDUIRoot` resolves those into component assigns:

- `binding_name`
- `bound_value`
- `refresh_meta`
- `state_key`
- `state_slice`
- `node_refresh`
- `node_variant`

This lets generic components stay small. A component can render `@bound_value`
or a `@state_slice` without knowing how the whole screen was built.

## Generic Live Components

The package's live-aware generic components are proof that the runtime contract
is reusable rather than CRUD-only:

- `AshSDUI.Components.StreamList`
- `AshSDUI.Components.MetricGrid`
- `AshSDUI.Components.StatusBadge`
- `AshSDUI.Components.ActivityFeed`
- `AshSDUI.Components.SelectionBar`

They should consume the runtime contract directly instead of requiring
domain-specific glue.

## What the Runtime Intentionally Does Not Promise Yet

AshSDUI is further along than the old bootstrap docs suggested, but a few
things are still intentionally modest:

- no formal `ui_selection` DSL
- no formal `ui_workflow` DSL
- no complete async intent lifecycle manager
- no promise of node-level LiveView process isolation
- no full cursor/range query model yet

Those are future extensions to this runtime, not signs that the current model is
invalid.
