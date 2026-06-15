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

## Core Concepts

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

### View and Recipe Overrides

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

Built-in generated components now share one runtime contract:

- `view` for the resolved `AshSDUI.View`
- `bindings` for named loaded data sources
- `state` for query and selection state
- `context` for actor, tenant, locale, and audience

That same contract is passed through `layout: :sdui` recipe trees, so generated
views and custom SDUI recipes can compose against the same surface.

### Storybook and Demo UI

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

For a fuller walkthrough, see [docs/authoring_generated_screens.md](/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/docs/authoring_generated_screens.md).

### Choosing an SDUI path

AshSDUI supports three related but distinct ways to render layouts. They share
the same `AshSDUI.Layout.Node` shape, but they solve different problems:

- Generated `layout: :sdui` views:
  `AshSDUI.LiveResource` resolves a view, calls `View.to_layout/2`, and
  renders the resulting tree immediately. Use this when your view should stay
  metadata-driven and the layout can be rebuilt from the view each request.
- Ephemeral runtime layouts:
  `AshSDUI.LiveScreen.assign_layout/3` registers a code-built tree, evicts the
  cache, renders it, and assigns it onto the socket. Use this when a LiveView
  needs to rebuild a temporary layout from current assigns.
- Persisted layouts:
  `AshSDUI.Layout.save/3`, `fetch/2`, `publish/2`, and `Renderer.to_tree/2`
  store and render named layouts backed by `AshSDUI.UINode` or a compatible
  custom `node_resource:`. Use this when a layout should survive process restarts
  or be edited and published separately from code deploys.

The guides below keep those flows separate on purpose:

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
Override `mount/3`, `handle_event/3`, or `render/1` in the module when an app
needs deeper behavior.

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
