# AshSDUI

## Ash-aware, recipe-driven, runtime-composable UI layer

Server-Driven UI for Phoenix LiveView applications backed by [Ash](https://hexdocs.pm/ash) resources. AshSDUI lets you define UI layouts as data — either in code or persisted in your database — and render them dynamically in LiveView without redeploying.

### Why ash_sdui has a real advantage:

- It has a clean conceptual split between metadata, view resolution, recipes, and render tree.
- The standalone UI modules are a nice boundary for humans and agents.
- It is less locked into “generated CRUD pages” as the final abstraction.
- It looks easier to steer toward product UI, not just admin UI.

## Features

- Define UI layouts as composable trees of typed components
- Persist and edit layouts at runtime via the unified `AshSDUI.Layout` API
- Code-based layouts for static or config-driven views
- Ash-first generated views through `AshSDUI.View` and `AshSDUI.LiveResource`
- Explicit runtime contract shared by generated views and SDUI layouts:
  `view`, `bindings`, `state`, and `context`
- Live collection bindings with poll, PubSub, and stream-style sources
- Generic runtime-aware components for lists, metrics, status, activity, and
  selection
- Registry-based component discovery with automatic scanning
- ETS-backed cache with automatic invalidation when `UINode` records change
- GraphQL fragment metadata on components for schema-driven tooling
- Audit trail via `ash_paper_trail` on all `UINode` changes

## Installation

```elixir
def deps do
  [
    {:ash_sdui, "~> 0.1"},
    {:phoenix_live_view, "~> 1"}
  ]
end
```

The built-in `AshSDUI.UINode` uses ETS storage for tests, demos, and local
prototypes. Production applications that need database-backed layouts should
define a compatible Ash resource and pass it as `node_resource: MyApp.SDUI.Node`.

## What It Is Today

AshSDUI started as a layout engine and generated-view helper. It now ships a
broader runtime model for Ash-backed LiveView screens.

The current public center of gravity is:

- `AshSDUI.View` for resolved screen metadata
- `AshSDUI.Binding` for named runtime data sources
- `AshSDUI.Intent` for normalized user actions
- `AshSDUI.LiveResource` for generated and semi-generated runtime hosting
- `AshSDUI.Components.SDUIRoot` for layout-rendered components that consume the
  same runtime contract

The older bootstrap plan and unified-component-graph exploration are useful
background only. This README is the main public entrypoint for the package as it
ships today.

## Preferred Authoring Paths

Prefer the smallest abstraction that still keeps the screen declarative:

1. `use AshSDUI.LiveResource`
2. `view/2`, `ui_field/2`, `ui_intent/2`, `ui_query/2`, and `ui_binding/2`
3. `ash_sdui_view_opts/4`
4. `recipe_overrides`
5. a custom recipe
6. a custom `render/1` or full custom LiveView

Prefer these APIs and metadata sources:

- `AshSDUI.Layout.Builder.resource/2` and `resources/3`
- `AshSDUI.Layout.fetch/2`, `register/2`, `save/3`, and `publish/2`
- `AshSDUI.LiveScreen.assign_layout/3` for ephemeral layouts
- `AshSDUI.Form.fields/2` plus metadata-driven forms/actions
- `ui_action` and `ui_attribute` metadata as the source of truth

Avoid new code that depends on `AshSDUI.Layout.Persistence` directly.

## Runtime Contract

Generated screens, `layout: :sdui` recipes, Storybook surfaces, and runtime
layouts share one contract:

- `view`
- `bindings`
- `state`
- `context`

`view` is the resolved `AshSDUI.View`. `bindings` holds named loaded values.
`state` carries query, selection, loading, refresh, workflow, and extra runtime
assigns. `context` carries actor, tenant, locale, audience, device, and custom
assigns.

When a view renders through an SDUI layout tree, nodes may also declare:

- `binding`
- `refresh`
- `variant`
- `state_key`

`AshSDUI.Components.SDUIRoot` injects those node-scoped runtime slices into
components as `bound_value`, `refresh_meta`, and `state_slice`.

### Components

A component is a Phoenix function component registered with AshSDUI. Declare one with `use AshSDUI.Component`:

```elixir
defmodule MyAppWeb.Components.Player.ScoreCard do
  use MyAppWeb, :live_component
  use AshSDUI.Component, fragment: """
    fragment PlayerScoreCardData on Player {
      displayName
      currentScore
      rank
    }
  """

  def render(assigns) do
    ~H"""
    <div class="score-card">
      <h2><%= @subject.display_name %></h2>
      <p>Score: <%= @subject.current_score %></p>
      <p>Rank: #<%= @subject.rank %></p>
    </div>
    """
  end
end
```

The component is automatically registered in `AshSDUI.Registry` under the name derived from its module (e.g., `"Player.ScoreCard@v1"`). Set `@version "v2"` before `use AshSDUI.Component` to override the default `v1`.

### Layouts

Layouts are named trees of component references. Define and register one in code:

```elixir
alias AshSDUI.Layout.Builder

root =
  Builder.resource(MyApp.UI.Resources.PlayerUI,
    region: :main,
    children: [
      Builder.node("Player.ActivityFeed@v1", region: :sidebar)
    ]
  )

AshSDUI.Layout.register("player-dashboard", root)
```

`AshSDUI.Layout.Builder` is the preferred way to author layout trees. It derives
the default component and `subject_resource` from SDUI resource metadata so you
rarely need to hand-build `%AshSDUI.Layout.Node{}` structs.

Store the same tree for runtime editing:

```elixir
AshSDUI.Layout.save("player-dashboard", root, status: :draft)
AshSDUI.Layout.publish("player-dashboard")
```

Renderers and LiveViews use the same layout name regardless of where it came from:

```elixir
AshSDUI.Renderer.to_tree("player-dashboard")
```

Use `AshSDUI.Layout.fetch/2` when you want the authored
`%AshSDUI.Layout.Node{}` definition tree, and `AshSDUI.Renderer.to_tree/2` when
you want the render-ready `%AshSDUI.Renderer.TreeNode{}` shape consumed by
`AshSDUI.Components.SDUIRoot`.

When a production app provides its own database-backed node resource, pass it at
the lookup boundary:

```elixir
AshSDUI.Layout.save("player-dashboard", root, node_resource: MyApp.SDUI.Node)
AshSDUI.Renderer.to_tree("player-dashboard", node_resource: MyApp.SDUI.Node)
```

A compatible `node_resource:` should expose the same layout fields as
`AshSDUI.UINode` plus `:create`, `:read`, `:destroy`, and `:publish` actions.

### LiveView Integration

Add `use AshSDUI` to any LiveView. It injects a `mount/3` that resolves and renders the layout tree, and a `sdui_root/1` component for rendering it:

```elixir
defmodule MyAppWeb.Live.PlayerDashboard do
  use MyAppWeb, :live_view
  use AshSDUI, lookup: {:from_params, :name}

  def render(assigns) do
    ~H"""
    <%= if @__sdui_tree__ do %>
      <.sdui_root />
    <% else %>
      <div>Layout not found</div>
    <% end %>
    """
  end
end
```

The `:lookup` option controls how the layout name is resolved:

| Strategy                        | Example                  | Resolves to                 |
| ------------------------------- | ------------------------ | --------------------------- |
| `{:from_params, :name}`         | `?name=player-dashboard` | `"player-dashboard"`        |
| `{:static, "player-dashboard"}` | —                        | Always `"player-dashboard"` |

You can override `mount/3` after `use AshSDUI` to add your own socket assigns — the injected mount is declared `defoverridable`.

For LiveViews that rebuild ephemeral layouts, use `AshSDUI.LiveScreen.assign_layout/3`
to register, evict, render, and assign the tree in one step.

### Generated Views and Recipe Overrides

`AshSDUI.LiveResource` can keep the LiveView tiny while still allowing targeted
customization from one predictable callback. Prefer `ash_sdui_view_opts/4`
over rebuilding `mount/3` when you only need to tweak labels, copy, or the
presentation of the built-in recipes.

```elixir
defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :index,
    domain: MyApp.Blog

  def ash_sdui_view_opts(_mode, _params, _session, _socket) do
    [
      recipe_overrides: [
        title: "Editorial Posts",
        empty_state: [
          title: "No posts yet",
          body: "Create the first story to populate the feed."
        ],
        fields: %{
          title: %{label: "Headline"}
        },
        intents: %{
          create: %{label: "Compose Post"}
        },
        toolbar: false,
        content: [props: %{class: "stacked-layout"}]
      ]
    ]
  end
end
```

The built-in generic recipe understands:

- `title`
- `empty_state`
- `fields`
- `intents`
- `toolbar`
- `content`
- `view`

Custom recipes can also read `view.assigns[:recipe_overrides]` to share the
same authoring surface for app-specific props instead of inventing another DSL.

That same contract is passed through `layout: :sdui` recipe trees, so generated
views and custom SDUI recipes compose against the same surface.

### Live Bindings and Intents

`AshSDUI.Binding` supports snapshot and live-friendly source families:

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

Current refresh semantics:

- `:manual`
- `:params`
- `:subscription`
- `{:interval, ms}`

Current update semantics:

- `:replace`
- `:append`
- `:prepend`
- `:merge`
- `:remove`

`AshSDUI.Intent` resolves declarative user actions into normalized command
envelopes. Built-in target families include:

- `{:navigate, path}`
- `{:patch, path}`
- `{:event, event}`
- `{:ash_action, action}`
- `{:refresh, binding_or_view}`
- `{:select, operation}`
- `{:workflow, event}`
- `{:custom, module, function}`

### Generated, Runtime, and Persisted Layouts

AshSDUI supports three related layout paths:

- Generated `layout: :sdui` views:
  `AshSDUI.LiveResource` resolves a view, calls `AshSDUI.View.to_layout/2`, and
  renders the resulting tree immediately.
- Ephemeral runtime layouts:
  `AshSDUI.LiveScreen.assign_layout/3` registers, evicts, renders, and assigns a
  code-built tree in one step.
- Persisted layouts:
  `AshSDUI.Layout.save/3`, `fetch/2`, and `publish/2` store and render named
  layouts backed by `AshSDUI.UINode` or a compatible custom `node_resource:`.

Persisted nodes store declarative metadata only. They do not persist runtime
binding values, refresh state, selection state, workflow progress, or
subscription registrations.

### Storybook and Demo

For generated UI demos, prefer `AshSDUI.Storybook` with `ui:` and `view:`
instead of hand-building raw trees:

```elixir
defmodule MyAppWeb.Storybook.Posts do
  use AshSDUI.Storybook,
    ui: MyApp.UI.PostUI,
    view: :index,
    bindings: %{collection: [%{id: "1", title: "Hello"}]}
end
```

This resolves the view, builds the recipe tree, and renders it through the same
`SDUIRoot` path used by `layout: :sdui`.

The demo app remains the public API tour:

- generated screens
- `/live/metrics`
- `/live/feed`
- `/live/selection`
- `/live/workflow`
- `/live/hybrid`
- Storybook leaves for reusable building blocks

Committed demo assets under
`examples/sdui_demo/priv/static/assets/` are intentional demo artifacts.
Crash dumps and transient runtime outputs are not part of the package contract.

Supporting docs:

- [docs/spec.md](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/docs/spec.md)
- [docs/runtime_model.md](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/docs/runtime_model.md)
- [docs/authoring_generated_screens.md](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/docs/authoring_generated_screens.md)
- [docs/persisted_sdui_layouts.md](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/docs/persisted_sdui_layouts.md)

## UINode Resource

`AshSDUI.UINode` is an Ash resource that stores individual nodes of a dynamic layout.

### Attributes

| Attribute           | Type       | Notes                                                  |
| ------------------- | ---------- | ------------------------------------------------------ |
| `:id`               | `:uuid`    | Primary key                                            |
| `:component_name`   | `:string`  | Required. Pattern: `^[A-Za-z0-9\.]+@v\d+$`             |
| `:static_props`     | `:map`     | Default: `%{}`                                         |
| `:subject_resource` | `:string`  | Optional Ash resource module name                      |
| `:subject_id`       | `:string`  | Optional. Use `"first"` to resolve the first record    |
| `:region`           | `:atom`    | Default: `:default`                                    |
| `:order`            | `:integer` | Default: `0`                                           |
| `:status`           | `:atom`    | `:draft`, `:published`, `:archived`. Default: `:draft` |
| `:name`             | `:string`  | Optional human label                                   |
| `:parent_id`        | `:uuid`    | Optional. Points to parent `UINode`                    |

### Actions

| Action     | Type    | Notes                          |
| ---------- | ------- | ------------------------------ |
| `:read`    | read    | Default                        |
| `:create`  | create  | Accepts all attributes         |
| `:update`  | update  | Accepts all attributes         |
| `:destroy` | destroy | Default                        |
| `:publish` | update  | Sets `:status` to `:published` |
| `:revert`  | update  | Sets `:status` to `:archived`  |

### Audit Trail

All changes to `UINode` are tracked via `ash_paper_trail` in `:changes_only` mode. This gives you a full revision history out of the box.

## Caching

`AshSDUI.Cache` is an ETS-backed cache keyed on layout name. Rendered trees are cached after the first render and automatically evicted whenever a relevant `UINode` is created, updated, or destroyed (via `AshSDUI.Notifier`).

Manual cache operations:

```elixir
AshSDUI.Cache.get("player-dashboard")   # {:ok, tree} | {:error, :not_found}
AshSDUI.Cache.evict("player-dashboard") # :ok
AshSDUI.Cache.flush()                   # clears all entries
```

## Component Registry

`AshSDUI.Registry` holds all discovered components. It is backed by ETS (fast concurrent reads) plus `persistent_term` (survives ETS resets).

```elixir
AshSDUI.Registry.lookup("Player.ScoreCard@v1")
# {:ok, %{module: MyAppWeb.Components.Player.ScoreCard, name: "Player.ScoreCard@v1",
#          fragment: "fragment PlayerScoreCardData on Player { ... }",
#          subject_types: ["Player"]}}

AshSDUI.Registry.all()
# [%{module: ..., name: ..., fragment: ..., subject_types: [...]}, ...]

AshSDUI.Registry.discover_components()
# Scans all loaded OTP applications and registers any module using AshSDUI.Component
```

## Subject Resolution

When a `UINode` has a `:subject_resource` and `:subject_id`, `AshSDUI.Calculations.ResolveSubject.resolve/1` fetches the live Ash record and passes it to the component as `@subject`. Using `"first"` as the subject ID returns the first record from the resource.

## Metadata-driven forms

Use `widget:` on `ui_field` entries to guide generated forms:

```elixir
sdui do
  view :index, recipe: :collection, read_action: :read
  view :show, recipe: :detail, read_action: :read
  view :new, recipe: :form, action: :create
  view :edit, recipe: :form, action: :update

  ui_field :title, label: "Title", widget: :text_input
  ui_field :body, label: "Body", widget: :textarea
  ui_field :email, label: "Email", widget: :email
end
```

`AshSDUI.Form.fields/2` combines that metadata with an Ash action's accepted
attributes so you can render forms from one source of truth.

## Resource Views and Layout Recipes

For higher-level frontends, use `AshSDUI.View` as the intermediate model between
Ash resources and concrete UI trees. A view resolves Ash actions, fields,
relationships, SDUI metadata, and runtime context into a data structure that a
layout recipe can render.

```elixir
{:ok, view} =
  AshSDUI.View.resolve(MyApp.UI.Resources.PostUI, :index,
    context: AshSDUI.Context.new(actor: current_user, audience: :customer)
  )

root = AshSDUI.View.to_layout!(view)
```

AshSDUI ships a generic recipe that emits stable semantic regions such as
`:toolbar` and `:content`. Applications can register their own recipes instead
of being limited to built-in preset names:

```elixir
defmodule MyApp.UI.Recipes.ArticleShow do
  @behaviour AshSDUI.LayoutRecipe

  def to_layout(view, _opts) do
    AshSDUI.Layout.Builder.node("Article.ShowShell@v1",
      static_props: %{mode: view.mode},
      children: [
        AshSDUI.Layout.Builder.node("Article.Body@v1", region: :content)
      ]
    )
  end
end

AshSDUI.LayoutRecipe.Registry.register(:article_show, MyApp.UI.Recipes.ArticleShow)
```

This keeps convenience layouts extensible: names like `:collection`, `:detail`,
or `:form` are recipes, not hardcoded framework concepts. A DaisyUI renderer can
be the default recipe set, while app-specific recipes can target any design
system or page structure.

### Contextual variants

Do not duplicate Ash authorization rules in UI metadata. Pass runtime context
into view resolution and use variant resolvers for presentation-only choices:

```elixir
customer_variant = fn view, %AshSDUI.Context{audience: :customer} ->
  %{view | fields: Enum.reject(view.fields, &(&1.name == :internal_notes))}
end

AshSDUI.View.resolve(MyApp.UI.Resources.PostUI, :show,
  context: [actor: current_user, tenant: tenant, audience: :customer],
  variant_resolvers: [customer_variant]
)
```

The context accepts `actor`, `tenant`, `locale`, `audience`, `device`, and
arbitrary `assigns`. Authorization-aware filtering can be added as one resolver;
audience, device, locale, or product-specific variants can be added as others.
That makes roles and groups app vocabulary instead of AshSDUI core concepts.

### Runtime bindings

`ui_binding` gives a view explicit named data sources.

Current source families include:

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

Current refresh modes include:

- `:manual`
- `:params`
- `:subscription`
- `{:interval, ms}`

Current update strategies include:

- `:replace`
- `:append`
- `:prepend`
- `:merge`
- `:remove`

Phoenix PubSub is the first live transport used by the package, but the public
contract stays binding-source based rather than PubSub-specific.

### Runtime intents

`ui_intent` has grown beyond static toolbar buttons.

Current target families include:

- `{:navigate, path}`
- `{:patch, path}`
- `{:event, event}`
- `{:ash_action, action}`
- `{:refresh, binding_or_view}`
- `{:select, operation}`
- `{:workflow, event}`
- `{:custom, module, function}`

Current behavioral metadata includes:

- `visible_when`
- `enabled_when`
- `loading_when`
- `refreshes`

`AshSDUI.Intent.command/3` is the canonical normalized command envelope. The
compatibility `execute/3` wrapper still exists for direct execution-style
consumers.

## Generated LiveResource Views

For conventional generated views, `AshSDUI.LiveResource` owns the repeated
LiveView plumbing:

```elixir
defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.Resources.PostUI,
    view: :index,
    domain: MyApp.Blog
end
```

The generated LiveView resolves the view, loads index/show data through Ash,
builds `AshPhoenix.Form` values for new/edit views, handles `"validate"`,
`"save"`, and `"delete"` events, and renders the package DaisyUI components.
It also hosts refresh, selection, workflow, and subscription-aware binding
behavior for the runtime slices demonstrated in the demo app. Override
`mount/3`, `handle_event/3`, or `render/1` in the module when an app needs
deeper behavior.

### What is still intentionally partial

AshSDUI's runtime is already broader than "CRUD scaffolding," but a few areas
are still intentionally modest:

- query extensions beyond current search/filter/sort/offset pagination
- full automatic async intent lifecycle management
- a dedicated `ui_selection` DSL
- a dedicated `ui_workflow` DSL
- fine-grained node-level rendering guarantees

Those are future extensions to the current runtime, not signs that the current
contract is temporary.

## Demo and Proof

`examples/sdui_demo` is the public API tour for the package. Its coverage matrix
maps every promoted feature to:

- a canonical route
- a Storybook surface when visual isolation helps
- at least one regression test

See [examples/sdui_demo/README.md](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/README.md).

### Built-in DaisyUI components

AshSDUI includes reusable Phoenix components for common generated views:

- `AshSDUI.Components.RecordForm`
- `AshSDUI.Components.IntentBar`
- `AshSDUI.Components.RecordList`
- `AshSDUI.Components.RecordDetail`
- `AshSDUI.Components.EmptyState`

These are defaults, not a closed design system. Apps can replace them from a
layout recipe, override fields/intents, or skip `LiveResource` and render custom
components directly.

## License

MIT
