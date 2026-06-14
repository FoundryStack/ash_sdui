defmodule SduiDemoWeb.Live.DemoLiveTest do
  use SduiDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "demo_live landing page" do
    test "renders editorial hero section with AshSDUI title", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "AshSDUI"
      assert html =~ "Server-driven UI for real Phoenix surfaces"
    end

    test "renders product highlights", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Screen recipes"
      assert html =~ "Override-first path"
      assert html =~ "LiveResource engine"
      assert html =~ "Storybook parity"
      assert html =~ "Ash-aware actions"
    end

    test "renders navigation links to blog posts", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "/posts"
      assert html =~ "/posts/generated"
      assert html =~ "Open the blog"
      assert html =~ "Open generated index"
    end

    test "renders refreshed how it works section", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "How it works"
      assert html =~ "Describe the resource"
      assert html =~ "Resolve a screen"
      assert html =~ "Render or override"
    end
  end
end
