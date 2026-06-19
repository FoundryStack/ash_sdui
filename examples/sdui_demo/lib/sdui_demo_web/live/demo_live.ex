defmodule SduiDemoWeb.Live.DemoLive do
  use SduiDemoWeb, :live_view

  @features [
    %{
      icon: "View",
      title: "View metadata",
      desc:
        "The demo resources now show `view`, `ui_field`, `ui_intent`, `ui_query`, and `ui_binding` as the public metadata vocabulary."
    },
    %{
      icon: "Query",
      title: "Query lifecycle",
      desc:
        "Search, filter, sort, pagination, and URL param sync are all visible on the generated collection route."
    },
    %{
      icon: "Recipe",
      title: "Recipe customization",
      desc:
        "The editorial journal route proves that `recipe_overrides` and an app recipe can reshape the same generated view contract."
    },
    %{
      icon: "Layout",
      title: "Layout API tour",
      desc:
        "Raw trees, code layouts, persisted layouts, and ephemeral runtime layouts each have a dedicated route so the public API stays concrete."
    },
    %{
      icon: "Storybook",
      title: "Storybook parity",
      desc:
        "Generated view stories, layout stories, and app-side components all share the same visual path as the demo routes."
    },
    %{
      icon: "Refresh",
      title: "Live runtime state",
      desc:
        "Refresh, selection, workflow, and node-level layout metadata are now explicit runtime concepts with generic components and event surfaces."
    },
    %{
      icon: "Stream",
      title: "Live collection bindings",
      desc:
        "Poll, PubSub, and stream-style bindings can update collections in place with append, merge, and remove strategies."
    }
  ]

  @showcases [
    %{
      tag: "Generated Views",
      title: "Posts index and detail",
      path: "/posts/generated",
      secondary_path: "/posts/generated",
      cta: "Open generated index",
      secondary_cta: "Open a generated detail from the table",
      api: "`AshSDUI.LiveResource` + built-in recipe",
      desc:
        "The built-in collection/detail path demonstrates metadata-driven fields, intents, query state, and the smallest override surface."
    },
    %{
      tag: "Custom Recipe",
      title: "Editorial journal",
      path: "/posts",
      secondary_path: "/storybook/components/editorial_posts_page",
      cta: "Open editorial route",
      secondary_cta: "Open editorial story",
      api: "`layout: :sdui` + custom recipe",
      desc:
        "The same `PostUI.index` view renders through an app recipe and page component without giving up the generated engine underneath."
    },
    %{
      tag: "Ephemeral Layouts",
      title: "Post show layout switcher",
      path: "/posts",
      secondary_path: "/posts",
      cta: "Open a post from the journal",
      secondary_cta: "Switch standard, blog, and minimal modes",
      api: "`AshSDUI.LiveScreen.assign_layout/3`",
      desc:
        "Per-record runtime layouts are rebuilt on the fly, then rendered through `SDUIRoot` with no persisted layout dependency."
    },
    %{
      tag: "Live Runtime",
      title: "Feed, metrics, selection, workflow, and hybrid layouts",
      path: "/live/feed",
      secondary_path: "/live/hybrid",
      cta: "Open live feed route",
      secondary_cta: "Open the hybrid layout route",
      api:
        "`AshSDUI.Binding`, `AshSDUI.Intent`, `AshSDUI.View.State`, `AshSDUI.LiveScreen.assign_layout/3`, live-aware components",
      desc:
        "The live runtime tour demonstrates collection subscriptions, refresh commands, selection-aware intents, workflow state, node-scoped layout metadata, and generic dashboard/feed primitives."
    },
    %{
      tag: "Layout API",
      title: "Raw, code, and persisted layouts",
      path: "/layouts/manage",
      secondary_path: "/storybook/layouts/raw_tree_showcase",
      cta: "Open layout tour",
      secondary_cta: "Open layout stories",
      api: "`AshSDUI.Layout` + `AshSDUI.Components.SDUIRoot`",
      desc:
        "The layout tour separates direct render trees, registered code layouts, and stored published layouts so each public path stays easy to explain."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, features: @features, showcases: @showcases)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.demo_page_layout features={@features} showcases={@showcases} />
    """
  end

  defp demo_page_layout(assigns) do
    SduiDemoWeb.Components.Layouts.DemoPageLayout.render(assigns)
  end
end
