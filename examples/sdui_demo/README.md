# AshSDUI Demo Coverage Matrix

This demo is the public proof surface for the current runtime spec.

It covers the package's evolution from generated CRUD views into a broader
runtime model with:

- explicit `view`, `bindings`, `state`, and `context`
- refreshable and subscribed bindings
- streaming collection updates
- selection and workflow state
- pending-action feedback, stale-data fallback, and runtime error surfaces
- hybrid layouts with node-scoped runtime metadata

Treat the matrix below as the acceptance map for promoted features. If a public
feature is missing from this table, it is not fully demoed yet.

This demo is a public API tour for `ash_sdui`. Each promoted feature should have:
- one canonical demo route,
- one Storybook entry when visual isolation helps,
- and one regression test.

| Feature | Demo route | Storybook | Regression proof | Public API |
| --- | --- | --- | --- | --- |
| Generated collection view | `/posts/generated` | `/storybook/components/post_ui` | `SduiDemoWeb.Live.BlogLiveTest` | `AshSDUI.LiveResource`, `view`, `ui_field`, `ui_intent`, `ui_query`, `ui_binding` |
| Generated detail view | `/posts/generated/:id` | `/storybook/components/post_ui_show` | `SduiDemoWeb.Live.BlogLiveTest` | `AshSDUI.LiveResource`, built-in detail recipe |
| Generated create form | `/posts/new` | `/storybook/components/post_ui_new` | `SduiDemoWeb.Live.BlogLiveTest` | `AshSDUI.LiveResource`, `AshSDUI.Form.fields/2` |
| Generated edit form | `/posts/:id/edit` | `/storybook/components/post_ui_edit` | `SduiDemoWeb.Live.BlogLiveTest` | `AshSDUI.LiveResource`, metadata-driven form rendering |
| Query lifecycle | `/posts/generated` | `/storybook/components/post_ui_filtered` | `SduiDemoWeb.Live.BlogLiveTest` | `AshSDUI.Query`, query params, sort, pagination, reset |
| Live collection bindings | `/live/feed` | `/storybook/components/stream_list` | `SduiDemoWeb.Live.LiveRuntimeTest` | `AshSDUI.Binding`, `AshSDUI.Components.StreamList`, PubSub-backed append/merge/remove updates |
| Refreshable runtime panels | `/live/metrics` | `/storybook/components/metric_grid` | `SduiDemoWeb.Live.LiveRuntimeTest` | `AshSDUI.View.State`, `AshSDUI.Intent`, `AshSDUI.Components.MetricGrid`, `AshSDUI.Components.ActivityFeed` |
| Runtime UX feedback | `/posts/generated`, `/live/metrics`, `/live/feed` | `/storybook/components/post_ui`, `/storybook/components/stream_list` | `AshSDUI.ComponentsTest`, `AshSDUI.LiveResourceTest` | `AshSDUI.View.State.pending`, `optimistic`, `offline`, `errors`, built-in runtime banners and loading states |
| Selection-aware intents | `/live/selection` | `/storybook/components/selection_bar` | `SduiDemoWeb.Live.LiveRuntimeTest` | `AshSDUI.View.State.selected`, `AshSDUI.Components.SelectionBar`, generic `intent` event surface |
| Workflow state | `/live/workflow` | `/storybook/components/status_badge` | `SduiDemoWeb.Live.LiveRuntimeTest` | `AshSDUI.View.State.workflow`, `AshSDUI.Components.StatusBadge`, workflow-targeted intents |
| Hybrid live layout | `/live/hybrid` | `/storybook/layouts/live_hybrid_layout` | `SduiDemoWeb.Live.LiveRuntimeTest` | `AshSDUI.LiveScreen.assign_layout/3`, node `binding`/`state_key`/`variant` metadata, `AshSDUI.Components.SDUIRoot` |
| Custom recipe path | `/posts` | `/storybook/components/editorial_posts_page` | `SduiDemoWeb.Live.BlogLiveTest` | `layout: :sdui`, `recipe_overrides`, app recipe |
| Ephemeral runtime layouts | `/posts/:id` | `/storybook/layouts/post_show_layout` | `SduiDemoWeb.Live.BlogLiveTest` | `AshSDUI.LiveScreen.assign_layout/3` |
| Raw render tree | `/layouts/raw-tree` | `/storybook/layouts/raw_tree_showcase` | `SduiDemoWeb.Live.LayoutShowcaseTest` | `AshSDUI.Layout.Builder.to_tree/1`, `AshSDUI.Components.SDUIRoot` |
| Registered code layout | `/layouts/code` | `/storybook/layouts/two_column_layout` | `SduiDemoWeb.Live.LayoutShowcaseTest` | `AshSDUI.Layout.Builder`, `AshSDUI.Layout.register/2`, `use AshSDUI` |
| Persisted layout | `/layouts/persisted` | `/storybook/layouts/persisted_layout_showcase` | `SduiDemoWeb.Live.LayoutShowcaseTest` | `AshSDUI.Layout.save/3`, `fetch/2`, `publish/2`, `AshSDUI.UINode` |
| Layout management tour | `/layouts/manage` | n/a | `SduiDemoWeb.Live.LayoutShowcaseTest` | `AshSDUI.Layout` public API |
| Homepage feature map | `/` | n/a | `SduiDemoWeb.Live.DemoLiveTest` | preferred vocabulary and route discovery |

When new public features are added to the library, update this matrix and add the matching route/story/test before calling the demo complete.
