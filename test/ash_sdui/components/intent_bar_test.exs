defmodule AshSDUI.Components.IntentBarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "renders navigate and patch intents with live navigation metadata" do
    html =
      render_component(&AshSDUI.Components.IntentBar.render/1,
        ui: AshSdui.MixProject,
        intents: [
          %{name: :go, label: "Go", target: {:navigate, "/posts"}},
          %{name: :filter, label: "Filter", target: {:patch, "/posts?sort=title"}}
        ]
      )

    assert html =~ ~s(data-phx-link="redirect")
    assert html =~ ~s(data-phx-link="patch")
    assert html =~ ~s(href="/posts")
    assert html =~ ~s(href="/posts?sort=title")
  end
end
