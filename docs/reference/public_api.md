# Public API Map

This document lists the public package surface for `ash_sdui`.

## Preferred authoring path

Prefer these layers in order:

1. `AshSDUI.LiveResource`
2. `view/2`, `ui_field/2`, `ui_intent/2`, `ui_query/2`, and `ui_binding/2`
3. `ash_sdui_view_opts/4`
4. `recipe_overrides`
5. custom recipe modules
6. custom `render/1` or full custom LiveViews

Prefer these APIs:

- `AshSDUI.Layout.Builder.resource/2`
- `AshSDUI.Layout.Builder.resources/3`
- `AshSDUI.Layout.fetch/2`
- `AshSDUI.Layout.register/2`
- `AshSDUI.Layout.save/3`
- `AshSDUI.Layout.publish/2`
- `AshSDUI.LiveScreen.assign_layout/3`
- `AshSDUI.Form.fields/2`

Compatibility-only path:

- `AshSDUI.Layout.Persistence`

## Core modules

| Module | Purpose |
| --- | --- |
| `AshSDUI.LiveResource` | Generated and semi-generated runtime host |
| `AshSDUI.View` | Resolved screen metadata and normalized UI model |
| `AshSDUI.Binding` | Binding planning, loading, subscriptions, and live updates |
| `AshSDUI.Intent` | Declarative action normalization and command envelopes |
| `AshSDUI.Layout` | Public API for registered and stored layout trees |
| `AshSDUI.Layout.Builder` | Preferred builder for layout authoring |
| `AshSDUI.LiveScreen` | Helper for assigning ephemeral runtime layouts |
| `AshSDUI.Form` | Metadata-driven form field introspection |
| `AshSDUI.Components.SDUIRoot` | Runtime bridge for layout-rendered components |
| `AshSDUI.Storybook` | Storybook integration for generated views and SDUI trees |

## Main functions

### `AshSDUI.Layout`

| Function | Purpose |
| --- | --- |
| `fetch/2` | Return a named layout definition from registered or stored sources |
| `register/2` | Register a code-authored layout by name |
| `save/3` | Persist a layout tree through `AshSDUI.UINode` or a compatible resource |
| `publish/2` | Mark stored layout nodes as published |
| `load_nodes/2` | Return stored node records for a layout name |

### `AshSDUI.Layout.Builder`

| Function | Purpose |
| --- | --- |
| `resource/2` | Build a node from a UI module or annotated resource |
| `resources/3` | Build one node per record from a UI module or annotated resource |
| `node/2` | Build a generic layout node |
| `register/2` | Register a built layout and return the layout name |
| `to_tree/1` | Convert a layout definition node into a renderable tree node |

### `AshSDUI.LiveScreen`

| Function | Purpose |
| --- | --- |
| `assign_layout/3` | Register, evict, render, and assign an ephemeral layout |

### `AshSDUI.Form`

| Function | Purpose |
| --- | --- |
| `fields/2` | Return ordered generated-form field metadata for an action |

## Metadata sources

Use resource metadata as the source of truth:

- `view/2`
- `ui_field/2`
- `ui_intent/2`
- `ui_query/2`
- `ui_binding/2`

Generated forms should use `widget:` when a field should render `:textarea`,
`:email`, or another non-default input.

## Binding source families

Supported `ui_binding` source families:

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

## Refresh modes

Supported normalized refresh modes:

- `:manual`
- `:params`
- `:subscription`
- `{:interval, ms}`

## Update strategies

Supported normalized update strategies:

- `:replace`
- `:append`
- `:prepend`
- `:merge`
- `:remove`

## Intent target families

Supported `ui_intent` target families:

- `{:navigate, path}`
- `{:patch, path}`
- `{:event, event}`
- `{:ash_action, action}`
- `{:refresh, binding_or_view}`
- `{:select, operation}`
- `{:workflow, event}`
- `{:custom, module, function}`

Supported behavioral metadata:

- `visible_when`
- `enabled_when`
- `loading_when`
- `refreshes`

## Runtime contract fields

Shared runtime values:

- `view`
- `bindings`
- `state`
- `context`

Node-level runtime metadata:

- `binding`
- `refresh`
- `variant`
- `state_key`

`AshSDUI.Components.SDUIRoot` injects component-facing runtime assigns:

- `binding_name`
- `bound_value`
- `refresh_meta`
- `state_key`
- `state_slice`
- `node_refresh`
- `node_variant`
