defmodule AshSDUI.ViewTest do
  use ExUnit.Case, async: false

  alias AshSDUI.Intent
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
end
