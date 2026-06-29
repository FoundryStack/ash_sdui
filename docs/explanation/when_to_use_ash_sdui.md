# When AshSDUI Pays Off

AshSDUI is most useful when your Phoenix LiveView UI is already centered on Ash
resources, actions, queries, and relationships. It is less useful when the UI
is mostly bespoke interaction logic with little reusable metadata.

This is not an either-or choice between AshSDUI and raw LiveView. The package
is designed as an authoring ladder:

1. `AshSDUI.LiveResource`
2. resource metadata such as `view`, `ui_field`, `ui_intent`, `ui_query`, and `ui_binding`
3. `ash_sdui_view_opts/4` and `recipe_overrides`
4. custom recipes and `layout: :sdui`
5. custom `render/1`
6. full custom LiveViews

That ladder is the practical boundary. Stay on the generated path while the
screen's complexity is mostly about resource metadata. Step down to custom
rendering or raw LiveView when the main complexity becomes workflow and
interaction orchestration.

## Where AshSDUI Pays Off

AshSDUI earns its keep when several screens share the same resource truths:

- form fields and widgets
- action labels and targets
- query, sort, filter, and pagination behavior
- relationship selectors and nested forms
- live bindings and refresh rules
- built-in UX feedback for pending actions and stale-data recovery
- layout structure that can be generated, composed, or persisted
- server-driven variants for different actors, tenants, audiences, devices, or runtime states

This is where duplicated LiveView code tends to drift. The same labels, field
lists, selectors, button intent, and query logic otherwise get repeated across
LiveViews, form components, stories, and tests.

In this repo, the package already provides a meaningful amount of reusable
surface:

- `AshSDUI.LiveResource` is the generic runtime host
- `AshSDUI.Form` introspects accepted fields, relationship selectors, and nested forms
- `AshSDUI.Layout.Builder` keeps layout trees declarative
- `AshSDUI.Components.SDUIRoot` bridges the runtime contract into layout-rendered components

That reuse matters more as the number of resources and screens grows.

## Server-Driven Interfaces

Server-driven UI is not only about storing a layout tree in a database. In
AshSDUI, the useful server-driven boundary is the point where the server
decides the view contract and the client renders it through LiveView.

The main server-side decision points are:

- `ash_sdui_context/3` for actor, tenant, locale, audience, device, and arbitrary assigns
- `ash_sdui_view_opts/4` for runtime recipe selection and `recipe_overrides`
- `variant_resolvers` for changing the resolved `AshSDUI.View` from context
- `layout: :sdui` recipes for selecting component composition from the resolved view
- `AshSDUI.LiveScreen.assign_layout/3` for rebuilding ephemeral layouts inside a LiveView
- node metadata such as `binding`, `refresh`, `variant`, and `state_key`
- intent metadata such as `visible_when`, `enabled_when`, `loading_when`, and `refreshes`

This gives you several levels of dynamism without forcing every component to
know the entire application state.

A screen can show action progress, keep rendering its last good state after a failed refresh,
and expose runtime failures without each page inventing its own state machine first.

Use `context` when the same screen should resolve differently for different
groups:

```elixir
def ash_sdui_context(_params, session, _socket) do
  %{
    actor: session["current_user"],
    tenant: session["tenant"],
    audience: session["role"],
    device: session["device"]
  }
end
```

Use `ash_sdui_view_opts/4` when the runtime context should select a recipe or
change recipe props:

```elixir
def ash_sdui_view_opts(_mode, _params, _session, socket) do
  case socket.assigns.ash_sdui_context.audience do
    :admin ->
      [recipe: :admin_dashboard]

    :customer ->
      [recipe: :customer_portal]

    _ ->
      [recipe: :collection]
  end
end
```

Use a recipe when the component composition itself changes. A recipe can choose
which root component to render, which children to include, and which props to
derive from records, bindings, or context.

Use `AshSDUI.LiveScreen.assign_layout/3` when the layout is truly runtime
specific. The demo post show page does this for per-record layout modes: it
loads the post and comments, builds a layout tree for the selected mode, and
assigns that tree without persisting it.

Use node metadata for component behavior that should remain local to the node.
For example, `binding` gives a component a focused `bound_value`, `state_key`
gives it a focused `state_slice`, and `variant` lets the server choose a
semantic rendering mode without hard-coding that choice inside the component.

The important boundary is complexity. Simple conditions fit metadata:
`requires_actor?`, `visible_when`, `enabled_when`, `loading_when`, and
`refreshes`. Complex conditions should usually live in ordinary Elixir:
`ash_sdui_view_opts/4`, a variant resolver, a recipe module, or the LiveView
that calls `assign_layout/3`.

That keeps AshSDUI from becoming a hidden rules engine. The package should
describe and carry the UI contract; application modules should still own
business-specific branching.

## Where Raw LiveView Is Better

Raw LiveView is usually the better fit when:

- the page is mostly a one-off experience
- the main complexity is highly custom event coordination
- the UI is not naturally driven by resource metadata
- the server-side layout rules are easier to read as one explicit LiveView
- you need very explicit control over rendering and event flow from the start

AshSDUI does not remove product complexity. It helps when the complexity is
repeated, metadata-shaped, and shared across screens. It helps less when each
screen is its own custom interaction system.

## Grounded LOC Ranges

The package demo gives a useful baseline for app-authored code.

Shared metadata for one resource:

- [post_ui.ex](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/lib/sdui_demo/ui/resources/post_ui.ex): `110 LOC`

Generated or semi-generated screens:

- [generated_posts_live.ex](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/lib/sdui_demo_web/live/generated_posts_live.ex): `31 LOC`
- [generated_post_show_live.ex](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/lib/sdui_demo_web/live/generated_post_show_live.ex): `21 LOC`
- [post_form_live.ex](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/lib/sdui_demo_web/live/post_form_live.ex): `101 LOC`

Hybrid and custom shell examples:

- [post_show_live.ex](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/lib/sdui_demo_web/live/post_show_live.ex): `198 LOC`
- [editorial_posts.ex](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/lib/sdui_demo/ui/recipes/editorial_posts.ex): `123 LOC`
- [editorial_posts_page.ex](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/lib/sdui_demo_web/components/editorial_posts_page.ex): `184 LOC`

Reasonable package-user estimates:

- Basic Ash resource frontend with index, show, new, and edit:
  AshSDUI app code is often about `160-250 LOC` once the metadata is shared.
  Raw LiveView for the same surface is often about `450-900 LOC`, depending on
  query controls, action bars, relationship selectors, and form complexity.
- Custom page shell over generated data:
  AshSDUI is often about `300-400 LOC` of app code for a recipe plus component.
  Raw LiveView is often about `380-600 LOC` for the same screen.
- One bespoke product page:
  Raw LiveView may be the smaller and clearer option.

These are not universal numbers. They are grounded estimates based on this repo
and on the kind of boilerplate AshSDUI already centralizes.

## Why It Helps LLM Agents

AshSDUI is particularly helpful for agent-authored UI because it reduces the
number of places where intent has to stay in sync.

Agents do better when:

- labels, widgets, and action targets live in one metadata surface
- the runtime host is already implemented
- loading, pending, and stale-data behavior already lives in the runtime host
- form fields come from introspection instead of hand-maintained lists
- layout trees can be built with a constrained builder API

That makes generated changes smaller and easier to verify. It also lowers the
chance that an agent updates a field label in one place while forgetting the
form renderer, action bar, Storybook story, or filter config elsewhere.

## Alternatives

Use raw Phoenix LiveView when you want maximum freedom and the UI does not need
another abstraction layer.

Use AshAdmin when the goal is a strong internal admin surface over Ash
resources.

Use Backpex when a Phoenix admin framework fits the app, especially outside an
Ash-first architecture.

Use AshSDUI when you want Ash-native UI metadata, generated or semi-generated
screens, and the ability to grow into recipes, layout trees, and runtime-aware
components without rewriting the whole path.

## Recommended Adoption Path

Start with one resource and one generated screen.

Add:

- `view`
- `ui_field`
- `ui_intent`
- `ui_query`
- `ui_binding` only when the screen needs live runtime data

Then use `ash_sdui_view_opts/4` and `recipe_overrides` before introducing a
custom recipe. Reach for a custom LiveView only when the generated or
recipe-based host stops matching the screen's coordination needs.
