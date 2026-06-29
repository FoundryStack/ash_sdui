# Runtime Contract

This document defines the current public runtime contract for `ash_sdui`.

## Canonical runtime values

Every generated or runtime-composed screen is described by:

- `view`
- `bindings`
- `state`
- `context`

When a view renders through an SDUI layout tree, nodes may also declare:

- `binding`
- `refresh`
- `variant`
- `state_key`

## `view`

`AshSDUI.View` is the normalized UI model for a screen.

Major fields:

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

Primary entry point:

- `AshSDUI.View.resolve/3`

## `state`

`AshSDUI.View.State` is the authoritative runtime state shape.

Fields:

- `query`
- `params`
- `selected`
- `loading`
- `pending`
- `optimistic`
- `offline`
- `errors`
- `refresh`
- `workflow`
- `assigns`

Definitions:

- `query`: normalized query state for collection-oriented views
- `params`: original or normalized request and event params
- `selected`: canonical list of selected identifiers
- `loading`: runtime loading flags keyed by feature or intent name
- `pending`: structured metadata for in-flight operations and optimistic work
- `optimistic`: last known optimistic payloads keyed by operation name
- `offline`: best-effort stale-data flag when the runtime cannot refresh cleanly
- `errors`: last known runtime errors keyed by operation name
- `refresh`: per-binding or per-view refresh metadata
- `workflow`: workflow state for view-local transitions
- `assigns`: extra runtime state outside the shared contract

## `bindings`

`ui_binding` defines named data sources for a view.

Author-facing source shapes:

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
- `{:actor}`
- `{:tenant}`

Runtime-resolved binding fields:

- `refresh`
- `update`
- `update_strategy`
- `source_kind`
- `status`
- `subscription`

Normalized refresh modes:

- `:manual`
- `:params`
- `:subscription`
- `{:interval, ms}`

Normalized update strategies:

- `:replace`
- `:append`
- `:prepend`
- `:merge`
- `:remove`

Public binding functions:

- `AshSDUI.Binding.plan/2`
- `AshSDUI.Binding.load/2`
- `AshSDUI.Binding.subscription_specs/2`
- `AshSDUI.Binding.apply_update/3`

## `context`

`AshSDUI.Context` carries runtime information about the current viewer or
environment.

Current fields:

- `actor`
- `tenant`
- `locale`
- `audience`
- `device`
- `assigns`

## `ui_intent`

`ui_intent` defines declarative user actions.

Intent metadata:

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

Target families:

- `{:navigate, path}`
- `{:patch, path}`
- `{:event, event}`
- `{:ash_action, action}`
- `{:refresh, binding_or_view}`
- `{:select, operation}`
- `{:workflow, event}`
- `{:custom, module, function}`

Primary intent functions:

- `AshSDUI.Intent.command/3`
- `AshSDUI.Intent.execute/3`

`AshSDUI.LiveResource` is the default dispatcher for built-in command types.

## Runtime host

`AshSDUI.LiveResource` is the primary runtime host for generated and
semi-generated screens.

Current responsibilities:

- resolve `AshSDUI.View`
- plan and load bindings
- mount and refresh runtime state
- register subscriptions
- handle binding-level live updates
- track pending operations, optimistic state, and offline fallback
- host query, refresh, select, workflow, and save event surfaces
- dispatch normalized intents
- render stock recipes or SDUI layout recipes through the same runtime contract

## Layout contract

Layouts are serializable trees with this preferred public authoring API:

- `AshSDUI.Layout.Builder.resource/2`
- `AshSDUI.Layout.Builder.resources/3`
- `AshSDUI.Layout.fetch/2`
- `AshSDUI.Layout.register/2`
- `AshSDUI.Layout.save/3`
- `AshSDUI.Layout.publish/2`
- `AshSDUI.LiveScreen.assign_layout/3`

`AshSDUI.Layout.Node` and `AshSDUI.Renderer.TreeNode` support these declarative
node metadata fields:

- `binding`
- `refresh`
- `variant`
- `state_key`

## Persisted layout guarantees

Persisted layout nodes store declarative runtime metadata only.

Runtime metadata is encoded inside `static_props` under an internal
`__ash_sdui__` envelope so it can round-trip through stored node records.

Persisted layouts do not store:

- runtime process state
- subscription registrations
- loaded binding values
- refresh status
- workflow progress
- selection state

## `SDUIRoot` injected assigns

`AshSDUI.Components.SDUIRoot` passes runtime values into layout-rendered
components.

Shared assigns:

- `node`
- `view`
- `bindings`
- `state`
- `context`

Component-facing node assigns:

- `binding_name`
- `bound_value`
- `refresh_meta`
- `state_key`
- `state_slice`
- `node_refresh`
- `node_variant`
