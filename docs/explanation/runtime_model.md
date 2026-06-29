# Runtime Model

AshSDUI uses one runtime model across generated screens, SDUI layouts, and
Storybook proof surfaces. The package no longer treats generated CRUD views and
layout-rendered screens as separate systems. Instead, both are different
authoring paths into one runtime contract.

## The shared contract

Every screen resolves into four shared values:

- `view`
- `bindings`
- `state`
- `context`

That contract is the center of gravity for the package. A generated collection
screen, a `layout: :sdui` recipe, and an ephemeral runtime layout can all be
described in the same language.

This is why the package can reuse the same runtime-aware components across
different authoring styles. The important thing is not how the screen was
authored, but that it can provide the same runtime contract at render time.

That shared contract also carries the baseline UX story: immediate loading
feedback, operation lifecycle tracking, and stale-data fallback live in the
same runtime model as views, bindings, and selection state.

## Why the runtime is split across modules

The package keeps separate responsibilities on purpose.

`AshSDUI.View` resolves Ash resource metadata and runtime options into a stable
screen description. `AshSDUI.Binding` turns declarative source definitions into
loaded values, refresh rules, and subscription behavior. `AshSDUI.LiveResource`
hosts the LiveView runtime and coordinates query updates, selections, workflow
state, refreshes, and intent dispatch. `AshSDUI.Components.SDUIRoot` bridges
that runtime into layout-rendered components.

This separation keeps the model inspectable. It also prevents generated screens
from becoming a closed rendering pipeline that only works for one screen shape.

## Lifecycle and ownership

A generated screen usually starts with `AshSDUI.View.resolve/3`, then moves
through binding planning and loading, then into `AshSDUI.LiveResource`, which
stores runtime state and registers subscriptions. Rendering happens either
through stock recipes or through `SDUIRoot` when the screen resolves to a layout
tree.

The important architectural choice is that `LiveResource` owns orchestration
while `View` and `Binding` own normalization. That split makes it possible to
grow runtime behavior without collapsing the whole system into LiveView-specific
callbacks.

That is what lets the package add UX behavior centrally. Pending actions,
optimistic bookkeeping, runtime banners, and offline recovery do not need to be
re-invented at each generated screen boundary.

## Node-scoped runtime

Layout nodes can opt into small slices of the runtime with `binding`, `refresh`,
`variant`, and `state_key`. `SDUIRoot` turns those into focused component
assigns such as `@bound_value`, `@refresh_meta`, and `@state_slice`.

This is a deliberate middle ground. Components stay smaller because they do not
need to understand the entire screen, but the package does not promise that each
node becomes its own isolated LiveView process.

## Why the runtime is broader than CRUD

The runtime model is built to host generated collection, detail, and form
screens, but it also supports live collection bindings, refreshable panels,
selection-aware actions, workflow state, and hybrid layouts. The generic
components in the package exist to prove that the contract is reusable for
product-facing runtime patterns, not just admin scaffolding.

This is also why Storybook and the demo app matter. They are proof that the
runtime abstractions hold up outside the narrowest generated path.

The package should prove that generated surfaces can stay responsive during actions
and remain readable when live refreshes fail, not just that they can render fields and lists.

## What is intentionally deferred

The runtime is stable without claiming to solve everything. It does not yet
offer a dedicated `ui_selection` DSL, a dedicated `ui_workflow` DSL, a full
async intent lifecycle manager, or a complete cursor and range query model. It
also does not promise node-level process isolation.

Those gaps are deliberate boundaries around the current model, not evidence that
the model is temporary.
