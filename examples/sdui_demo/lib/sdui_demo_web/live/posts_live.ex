defmodule SduiDemoWeb.Live.PostsLive do
  use AshSDUI.LiveResource,
    resource: SduiDemo.UI.Resources.PostUI,
    screen: :index,
    domain: SduiDemo.Blog

  def ash_sdui_screen_opts(_mode, _params, _session, _socket) do
    [
      recipe_overrides: [
        title: "AshSDUI Journal",
        empty_state: [
          title: "No posts yet",
          body: "Create your first entry to see the editorial recipe in action."
        ],
        screen: [
          props: %{
            subtitle:
              "A generated index shaped by an app-side recipe, tuned through recipe_overrides.",
            create_label: "Create Post"
          }
        ]
      ]
    ]
  end
end
