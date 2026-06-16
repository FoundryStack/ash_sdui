defmodule SduiDemoWeb.Live.DemoLiveTest do
  use SduiDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "demo_live landing page" do
    test "renders editorial hero section with AshSDUI title", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "AshSDUI"
      assert html =~ "Server-driven UI for real Phoenix surfaces"
      assert html =~ "Feature Tour"
    end

    test "renders product highlights", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "View metadata"
      assert html =~ "Query lifecycle"
      assert html =~ "Recipe customization"
      assert html =~ "Layout API tour"
      assert html =~ "Storybook parity"
    end

    test "renders navigation links to showcase routes", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "/posts"
      assert html =~ "/posts/generated"
      assert html =~ "/layouts/manage"
      assert html =~ "Open the blog"
      assert html =~ "Open generated index"
      assert html =~ "Open layout tour"
    end

    test "renders refreshed how it works section", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "How it works"
      assert html =~ "Describe the resource"
      assert html =~ "Resolve a view"
      assert html =~ "Render, persist, or override"
    end

    test "renders the demo feature map", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Generated Views"
      assert html =~ "Custom Recipe"
      assert html =~ "Ephemeral Layouts"
      assert html =~ "Layout API"
    end
  end
end
