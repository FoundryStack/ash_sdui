defmodule SduiDemoWeb.Live.LiveRuntimeTest do
  use SduiDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "live runtime demo routes" do
    test "feed route renders the live collection surface and applies append merge remove", %{
      conn: conn
    } do
      {:ok, view, html} = live(conn, "/live/feed")

      assert html =~ "Live Feed"
      assert html =~ "Initial collection snapshot"

      html =
        view
        |> element("button", "Append Item")
        |> render_click()

      assert html =~ "Appended item"

      html =
        view
        |> element("button", "Merge First")
        |> render_click()

      assert html =~ "(merged)"

      html =
        view
        |> element("button", "Remove First")
        |> render_click()

      refute html =~ "Initial collection snapshot"
    end

    test "metrics route renders refreshable panels and activity feed", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/live/metrics")

      assert html =~ "Refreshable runtime panels"
      assert html =~ "Active sessions"
      assert html =~ "Bindings loaded"
    end

    test "hybrid route mixes generated layout nodes with runtime-bound components", %{conn: conn} do
      {:ok, view, html} = live(conn, "/live/hybrid")

      assert html =~ "Generated resources inside a live runtime tree"
      assert html =~ "Live binding collection"
      assert html =~ "Initial collection snapshot"
      assert html =~ "post-card"

      html =
        view
        |> element("button", "Append Activity")
        |> render_click()

      assert html =~ "Hybrid event"

      html =
        view
        |> element("button[phx-value-intent='queue_review']")
        |> render_click()

      assert html =~ "review"
    end

    test "selection route toggles selection state and shows selection bar", %{conn: conn} do
      {:ok, view, html} = live(conn, "/live/selection")

      assert html =~ "Selection-aware intents"
      refute html =~ "items selected"

      html =
        view
        |> element("input[phx-value-id='sel-1']")
        |> render_click()

      assert html =~ "items selected"
      assert html =~ "font-semibold\">1</span>"
      assert html =~ "Pin Selection"
    end

    test "workflow route updates status badge through intent events", %{conn: conn} do
      {:ok, view, html} = live(conn, "/live/workflow")

      assert html =~ "Workflow-driven surfaces"
      assert html =~ "draft"

      html =
        view
        |> element("button[phx-value-intent='queue_review']")
        |> render_click()

      assert html =~ "review"
    end
  end
end
