defmodule AshSDUI.ViewTest do
  use ExUnit.Case, async: false

  alias AshSDUI.Intent
  alias AshSDUI.Binding
  alias AshSDUI.Layout
  alias AshSDUI.Query
  alias AshSDUI.Resource.Info
  alias AshSDUI.TestFixtures.ScreenArticle
  alias AshSDUI.TestFixtures.ViewArticleUI
  alias AshSDUI.View

  test "resolve/3 builds a generic view from V2 DSL metadata" do
    assert {:ok, view} =
             View.resolve(ViewArticleUI, :index,
               params: %{
                 "search" => "guide",
                 "sort" => "-title",
                 "filters" => %{"title" => "Guide"},
                 "limit" => "10"
               }
             )

    assert view.resource == ScreenArticle
    assert view.mode == :index
    assert view.recipe == :collection
    assert view.assigns.title == "Knowledge Base"

    assert Enum.map(view.fields, & &1.name) == [:title]
    assert Enum.map(view.intents, & &1.name) == [:create]
    assert Enum.map(view.bindings, & &1.name) == [:collection, :record]

    assert [%Query{} = query] = view.queries
    assert query.search == "guide"
    assert query.filters == %{title: "Guide"}
    assert query.sort == [{:title, :desc}]
    assert query.limit == 10
  end

  test "to_layout/2 renders the view directly" do
    assert {:ok, view} = View.resolve(ViewArticleUI, :index)
    assert {:ok, layout} = View.to_layout(view)

    assert %Layout.Node{} = layout
    assert layout.component == "AshSDUI.GenericView@v1"

    assert Enum.find(layout.children, &(&1.region == :toolbar)).component ==
             "AshSDUI.IntentBar@v1"
  end

  test "resource info exposes the V2 DSL entities" do
    assert Enum.map(Info.views(ViewArticleUI), & &1.name) == [:index, :show, :new]
    assert Enum.map(Info.ui_fields(ViewArticleUI), & &1.name) == [:title, :body]
    assert Enum.map(Info.ui_intents(ViewArticleUI), & &1.name) == [:create, :update]
    assert Enum.map(Info.ui_queries(ViewArticleUI), & &1.name) == [:default]
    assert Enum.map(Info.ui_bindings(ViewArticleUI), & &1.name) == [:collection, :record]
  end

  test "intent execute normalizes navigation and ash action targets" do
    [create, update] = Info.ui_intents(ViewArticleUI)

    assert {:ok, {:navigate, "/articles/new"}} =
             create
             |> Intent.resolve(ViewArticleUI)
             |> Intent.execute(%{})

    assert {:ok, {:ash_action, :update, %{title: "Updated"}, runtime}} =
             update
             |> Intent.resolve(ViewArticleUI)
             |> Intent.execute(%{title: "Updated"}, resource: ScreenArticle)

    assert runtime.resource == ScreenArticle
  end

  test "intent command returns normalized envelopes for generic runtime targets" do
    intent =
      Intent.resolve(%{
        name: :refresh_metrics,
        label: "Refresh",
        target: {:refresh, :metrics},
        refreshes: [:metrics]
      })

    assert {:ok, command} = Intent.command(intent, %{id: "metric-1"}, %{resource: ScreenArticle})
    assert command.type == :refresh
    assert command.intent == :refresh_metrics
    assert command.payload == %{id: "metric-1"}
    assert command.meta.binding == :metrics
    assert command.meta.refreshes == [:metrics]
  end

  test "binding resolve infers runtime metadata for generic source families" do
    binding =
      Binding.resolve(
        %{name: :audience, source: {:context, :audience}, refresh: :params, update: :merge},
        %{audience: :staff}
      )

    assert binding.value == :staff
    assert binding.refresh == :params
    assert binding.update == :merge
    assert binding.source_kind == :context
    assert binding.status == :ready
  end

  test "binding resolve normalizes live collection sources" do
    binding =
      Binding.resolve(%{
        name: :feed,
        source:
          {:pubsub, "ash_sdui:feed",
           [source: {:assign, :seed_feed}, event: :feed_update, reducer: :stream_event, key: :id]},
        many?: true,
        update: :merge
      })

    assert binding.refresh == :subscription
    assert binding.update_strategy == :merge
    assert binding.source_kind == :pubsub
    assert binding.subscription.topic == "ash_sdui:feed"
    assert binding.subscription.event == :feed_update
    assert binding.subscription.key == :id
  end

  test "binding applies append merge and remove strategies for live collections" do
    binding =
      Binding.resolve(%{
        name: :feed,
        source:
          {:stream, {:assign, :seed_feed},
           [event: :feed_update, reducer: :stream_event, key: :id]},
        many?: true,
        update: :append
      })

    current = [%{id: "1", title: "First"}]

    assert {:ok, appended, _meta} =
             Binding.apply_update(
               binding,
               current,
               {:ash_sdui_event, :feed_update,
                %{operation: :append, item: %{id: "2", title: "Second"}}}
             )

    assert Enum.map(appended, & &1.id) == ["1", "2"]

    assert {:ok, merged, _meta} =
             Binding.apply_update(
               %{binding | update: :merge, update_strategy: :merge},
               appended,
               {:ash_sdui_event, :feed_update,
                %{operation: :merge, item: %{id: "1", title: "Updated"}}}
             )

    assert Enum.find(merged, &(&1.id == "1")).title == "Updated"

    assert {:ok, removed, _meta} =
             Binding.apply_update(
               %{binding | update: :remove, update_strategy: :remove},
               merged,
               {:ash_sdui_event, :feed_update, %{operation: :remove, id: "2"}}
             )

    assert Enum.map(removed, & &1.id) == ["1"]
  end
end
