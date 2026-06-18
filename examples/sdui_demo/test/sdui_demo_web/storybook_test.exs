defmodule SduiDemoWeb.StorybookTest do
  use SduiDemoWeb.ConnCase, async: false

  @app_css "/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/assets/css/app.css"
  @endpoint_source "/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/lib/sdui_demo_web/endpoint.ex"
  @dev_config "/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/config/dev.exs"
  @mixfile "/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/mix.exs"

  test "storybook backend discovers component stories" do
    paths =
      SduiDemoWeb.Storybook.leaves()
      |> Enum.map(& &1.path)

    assert "/components/editorial_posts_page" in paths
    assert "/components/post_ui_show" in paths
    assert "/components/post_ui_new" in paths
    assert "/components/post_ui_edit" in paths
    assert "/components/post_ui_filtered" in paths
    assert "/components/post_publish_hint_field" in paths
    assert "/components/resource_actions" in paths
    assert "/components/resource_form" in paths
    assert "/components/stream_list" in paths
    assert "/components/user_card" in paths
    assert "/layouts/live_hybrid_layout" in paths
    assert "/layouts/raw_tree_showcase" in paths
    assert "/layouts/persisted_layout_showcase" in paths
  end

  test "storybook redirects to the first discovered component story", %{conn: conn} do
    conn = get(conn, "/storybook")

    assert redirected_to(conn) == "/storybook/components/comment_item"
  end

  test "storybook pages load the demo stylesheet", %{conn: conn} do
    conn = get(conn, "/storybook/components/post_ui_show")

    assert html_response(conn, 200) =~ ~s(@import "/assets/app.css?hash=)
  end

  test "storybook iframe loads the demo stylesheet from an absolute path", %{conn: conn} do
    conn = get(conn, "/storybook/iframe/layouts/raw_tree_showcase")

    assert html_response(conn, 200) =~ ~s(@import "/assets/app.css?hash=)
  end

  test "storybook uses the shared app stylesheet contract" do
    assert File.read!(@app_css) =~ ~s(@import "./demo_base.css";)

    refute File.exists?(
             "/Users/maxsvargal/Documents/Projects/foundry/packages/ash_sdui/examples/sdui_demo/assets/css/storybook.css"
           )
  end

  test "dev endpoint is wired for browser live reload" do
    assert File.read!(@endpoint_source) =~
             "socket(\"/phoenix/live_reload/socket\", Phoenix.LiveReloader.Socket)"

    assert File.read!(@endpoint_source) =~ "plug(Phoenix.LiveReloader)"
    assert File.read!(@dev_config) =~ "live_reload:"
    assert File.read!(@dev_config) =~ "lib/ash_sdui"
    assert File.read!(@mixfile) =~ "{:phoenix_live_reload,"
  end
end
