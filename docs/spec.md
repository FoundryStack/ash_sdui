# AshSDUI Runtime Specification

**Status:** Accepted and implemented in the current package surface  
**Last updated:** June 17, 2026

## Purpose

This document is the concise normative reference for `ash_sdui` public
behavior.

Earlier architecture work explored a broader "unified component graph" model as
the primary abstraction. The package that ships today is more concrete:

- Ash-first UI metadata resolves into `AshSDUI.View`
- `AshSDUI.LiveResource` hosts generated and semi-generated screens
- layouts remain first-class and persistable
- the runtime contract is explicit and reusable across generated views,
  Storybook, and custom SDUI layouts

Treat older bootstrap plans and component-graph writeups as historical context.
Start with `README.md` for the public overview, then use this spec when
implementing or reviewing current features.

## Canonical Runtime Contract

Every generated or runtime-composed screen should be understandable in terms of:

- `view`
- `bindings`
- `state`
- `context`

When a view is rendered through an SDUI layout tree, nodes may also declare:

- `binding`
- `refresh`
- `variant`
- `state_key`

`AshSDUI.Components.SDUIRoot` is the bridge between those runtime values and
rendered components.

## Public Model

`AshSDUI.View` is the package's normalized, inspectable UI model.

Its major fields are:

- `resource`
- `ui`
- `name`
- `mode`
- `action`
- `recipe`
- `context`
- `fields`
- `intents`
- `bindings`
- `queries`
- `state`
- `relationships`
- `assigns`
- `refresh`
- `workflow`

`AshSDUI.View.resolve/3` is the primary entry point for generated UIs. It
combines resource metadata, runtime params, query state, bindings, and variant
resolvers into one struct that recipes and LiveViews can consume.

`AshSDUI.View.State` is the authoritative runtime state shape. It currently
includes:

- `query`
- `params`
- `selected`
- `loading`
- `refresh`
- `workflow`
- `assigns`

- `query`: normalized query state for collection-oriented views
- `params`: original or normalized request/event params
- `selected`: canonical list of selected identifiers
- `loading`: runtime loading flags keyed by feature or intent name
- `refresh`: per-binding or per-view refresh metadata
- `workflow`: generic workflow state for view-local transitions
- `assigns`: extra runtime state that does not fit the shared contract

## Binding Contract

`ui_binding` defines named data sources for a view. `AshSDUI.Binding` resolves
those declarations into runtime bindings with normalized metadata.

Author-facing source shapes currently supported:

- `{:resource, resource}`
- `{:relationship, relationship}`
- `{:assign, key}`
- `{:context, key}`
- `{:runtime, key}`
- `{:selection}`
- `{:subject}`
- `{:event, key}`
- `{:poll, source, interval: ms}`
- `{:pubsub, topic, ...}`
- `{:stream, source, ...}`

Context aliases are also supported:

- `{:actor}`
- `{:tenant}`

Runtime-resolved binding structs include:

- `refresh`
- `update`
- `update_strategy`
- `source_kind`
- `status`
- `subscription`

Those are runtime fields, not extra author-facing DSL concepts.

Current normalized refresh modes:

- `:manual`
- `:params`
- `:subscription`
- `{:interval, ms}`

Current normalized update strategies:

- `:replace`
- `:append`
- `:prepend`
- `:merge`
- `:remove`

Bindings can be planned with `AshSDUI.Binding.plan/2`, loaded with
`AshSDUI.Binding.load/2`, subscribed through
`AshSDUI.Binding.subscription_specs/2`, and updated with
`AshSDUI.Binding.apply_update/3`.

Phoenix PubSub is the first concrete live transport used by the package, but
the public binding model stays source-based rather than transport-specific.

The spec does not require PubSub to remain the only transport. Future
subscription adapters should fit into the same binding contract without forcing
DSL redesign.

## Intent Contract

`ui_intent` defines declarative user actions. `AshSDUI.Intent` resolves those
declarations into a normalized, inspectable model and command envelope.

Current intent metadata includes:

- `name`
- `label`
- `style`
- `icon`
- `component_override`
- `target`
- `confirm`
- `placement`
- `requires_actor?`
- `visible_when`
- `enabled_when`
- `loading_when`
- `refreshes`

- `{:navigate, path}`
- `{:patch, path}`
- `{:event, event}`
- `{:ash_action, action}`
- `{:refresh, binding_or_view}`
- `{:select, operation}`
- `{:workflow, event}`
- `{:custom, module, function}`

`AshSDUI.Intent.command/3` returns the normalized command envelope for a
resolved intent.

`AshSDUI.Intent.execute/3` preserves compatibility for direct execution-style
consumers, but the command envelope is the canonical runtime representation.

`AshSDUI.LiveResource` is the default dispatcher for built-in command types.

## Runtime Host

`AshSDUI.LiveResource` is the primary generic runtime host for generated and
semi-generated screens.

Its current responsibilities include:

- resolve `AshSDUI.View`
- plan and load bindings
- mount and refresh runtime state
- register subscriptions
- handle binding-level live updates
- host query, refresh, select, workflow, and save event surfaces
- dispatch normalized intents
- render stock recipes or SDUI layout recipes through the same runtime contract

Generated collection, detail, and form screens should be treated as runtime
specializations built on this host rather than as a separate rendering system.

## Layout Contract

Layouts remain serializable trees with a stable public authoring API.

Preferred authoring and lookup APIs:

- `AshSDUI.Layout.Builder.resource/2`
- `AshSDUI.Layout.Builder.resources/3`
- `AshSDUI.Layout.fetch/2`
- `AshSDUI.Layout.register/2`
- `AshSDUI.Layout.save/3`
- `AshSDUI.Layout.publish/2`
- `AshSDUI.LiveScreen.assign_layout/3`

`AshSDUI.Layout.Node` and `AshSDUI.Renderer.TreeNode` support:

- `binding`
- `refresh`
- `variant`
- `state_key`

These values are declarative and component-facing. They do not imply process
isolation or separate LiveView processes per node.

### Persisted layout behavior

Persisted layout nodes store runtime metadata inside `static_props` under an
internal `__ash_sdui__` envelope.

Persisted layouts store only declarative node metadata. Runtime process state,
subscription registrations, and in-memory refresh status are never persisted.

## SDUIRoot Contract

`AshSDUI.Components.SDUIRoot` passes the runtime contract into layout-rendered
components.

The key injected assigns are:

- `node`
- `view`
- `bindings`
- `state`
- `context`
- `binding_name`
- `bound_value`
- `refresh_meta`
- `state_key`
- `state_slice`
- `node_refresh`
- `node_variant`

Generic components should prefer consuming that contract instead of inventing
parallel adapter layers.

## Query Model

The current query model supports:

- search
- field filters
- sorting
- default sort
- limit/page offset pagination
- reset/query lifecycle events

### Explicitly not yet implemented as first-class features

The following are future work and should not be described as fully supported:

- range filters
- cursor pagination
- richer grouped filter logic
- stronger multi-sort UX semantics beyond current normalized sort support

Future query work should extend the existing model rather than replace it.

## Selection Semantics

Selection is currently runtime state, not a separate DSL entity.

The canonical stored form is selected IDs in `state.selected`.
`LiveResource` may also hydrate convenience values like selected records for
rendering, but those are implementation helpers rather than persisted concepts.

`ui_selection` is intentionally deferred until the runtime-only selection model
stops being sufficient.

## Workflow Semantics

Workflow is currently generic runtime state plus workflow-targeted intents.

AshSDUI does not yet ship a formal workflow DSL. The public contract is:

- views may expose workflow metadata
- runtime state stores workflow values in `state.workflow`
- intents may target workflow events

`ui_workflow` remains intentionally deferred until the use cases justify a
formal declarative schema.

## Loading and Async Semantics

`loading_when` is currently declarative render metadata, not a full automatic
async intent lifecycle manager.

The long-term direction is to standardize loading state through
`state.loading[intent_name]` and related runtime keys, but that lifecycle is not
yet fully automated across all intent types.

Docs, examples, and reviews should describe the current loading behavior
accurately rather than imply a generalized async state machine.

## Demo as Proof Surface

`examples/sdui_demo` is the public API tour for the library. The demo coverage
matrix in `/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/README.md`
acts as the proof map between:

- public features
- canonical demo routes
- Storybook surfaces
- regression tests

New public features should not be considered complete until that matrix is
updated.

## Remaining Roadmap Themes

The current implementation is intentionally generic, but a few areas remain open
for future enhancement:

- query extensions
- deeper async intent lifecycle management
- optional workflow DSL formalization
- more explicit transport adapters beyond Phoenix PubSub
- stronger component-level live ergonomics built on the existing runtime

Those should be treated as additive work on top of the runtime contract in this
spec, not as reasons to redesign the package again.
