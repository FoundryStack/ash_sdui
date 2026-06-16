defmodule SduiDemoWeb.Live.LayoutShowcaseTest do
  use SduiDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias AshSDUI.Layout
  alias AshSDUI.UINode

  setup do
    AshSDUI.Registry.init_table()
    SduiDemo.DemoData.bootstrap()
    Ash.DataLayer.Ets.stop(UINode)
    Ash.DataLayer.Ets.stop(UINode.Version)
    :ok
  end

  test "raw tree route renders a direct SDUI tree", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/layouts/raw-tree")

    assert html =~ "Direct SDUIRoot rendering"
    assert html =~ ~s(data-testid="two-column-layout")
    assert html =~ ~s(data-testid="user-card")
    assert html =~ ~s(data-testid="post-card")
  end

  test "code layout route renders a registered layout by name", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/layouts/code")

    assert html =~ "Registered layout via AshSDUI.Layout"
    assert html =~ "demo-code-layout"
    assert html =~ ~s(data-testid="two-column-layout")

    assert {:ok, layout} = Layout.fetch("demo-code-layout", source: :registered)
    assert layout.root.component == "Layouts.TwoColumnLayout@v1"
  end

  test "persisted layout route renders a published stored layout", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/layouts/persisted")

    assert html =~ "Published layout loaded from AshSDUI.UINode"
    assert html =~ "demo-persisted-layout"
    assert html =~ ~s(data-testid="two-column-layout")

    assert {:ok, nodes} = Layout.load_nodes("demo-persisted-layout", status: :published)
    assert Enum.all?(nodes, &(&1.status == :published))
  end

  test "layout admin route drives code and persisted layout actions", %{conn: conn} do
    {:ok, view, html} = live(conn, "/layouts/manage")

    assert html =~ "Manage code and persisted demo layouts"
    assert html =~ "Register code layout"
    assert html =~ "Save draft"
    assert html =~ "Publish"

    view
    |> element("button[phx-click='register_code_layout']")
    |> render_click()

    assert render(view) =~ "Registered?"
    assert render(view) =~ "Yes"
    assert {:ok, _layout} = Layout.fetch("demo-code-layout", source: :registered)

    view
    |> element("button[phx-click='publish_persisted_layout']")
    |> render_click()

    html = render(view)
    assert html =~ "Persisted layout"
    assert html =~ "Open persisted route"
  end
end
