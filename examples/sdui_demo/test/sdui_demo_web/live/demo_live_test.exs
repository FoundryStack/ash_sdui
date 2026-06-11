defmodule SduiDemoWeb.Live.DemoLiveTest do
  use SduiDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "demo_live landing page" do
    test "renders hero section with AshSDUI title", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "AshSDUI"
      assert html =~ "Server-driven UI"
    end

    test "renders feature cards", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Tree-based layout"
      assert html =~ "Multi-resource nesting"
      assert html =~ "i18n via gettext"
      assert html =~ "Storybook integration"
    end

    test "renders navigation links to blog posts", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "/posts"
      assert html =~ "Browse Blog Posts"
    end

    test "renders how it works section", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "How it works"
      assert html =~ "AshSDUI.Renderer"
    end
  end
end
