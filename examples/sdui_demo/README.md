# AshSDUI Demo Coverage Matrix

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
| Custom recipe path | `/posts` | `/storybook/components/editorial_posts_page` | `SduiDemoWeb.Live.BlogLiveTest` | `layout: :sdui`, `recipe_overrides`, app recipe |
| Ephemeral runtime layouts | `/posts/:id` | `/storybook/layouts/post_show_layout` | `SduiDemoWeb.Live.BlogLiveTest` | `AshSDUI.LiveScreen.assign_layout/3` |
| Raw render tree | `/layouts/raw-tree` | `/storybook/layouts/raw_tree_showcase` | `SduiDemoWeb.Live.LayoutShowcaseTest` | `AshSDUI.Layout.Builder.to_tree/1`, `AshSDUI.Components.SDUIRoot` |
| Registered code layout | `/layouts/code` | `/storybook/layouts/two_column_layout` | `SduiDemoWeb.Live.LayoutShowcaseTest` | `AshSDUI.Layout.Builder`, `AshSDUI.Layout.register/2`, `use AshSDUI` |
| Persisted layout | `/layouts/persisted` | `/storybook/layouts/persisted_layout_showcase` | `SduiDemoWeb.Live.LayoutShowcaseTest` | `AshSDUI.Layout.save/3`, `fetch/2`, `publish/2`, `AshSDUI.UINode` |
| Layout management tour | `/layouts/manage` | n/a | `SduiDemoWeb.Live.LayoutShowcaseTest` | `AshSDUI.Layout` public API |
| Homepage feature map | `/` | n/a | `SduiDemoWeb.Live.DemoLiveTest` | preferred vocabulary and route discovery |

When new public features are added to the library, update this matrix and add the matching route/story/test before calling the demo complete.
