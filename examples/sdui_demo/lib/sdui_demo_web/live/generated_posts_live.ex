defmodule SduiDemoWeb.Live.GeneratedPostsLive do
  use AshSDUI.LiveResource,
    ui: SduiDemo.UI.Resources.PostUI,
    view: :index,
    domain: SduiDemo.Blog

  def ash_sdui_view_opts(_mode, _params, _session, _socket) do
    [
      recipe: :collection,
      assigns: %{layout: nil},
      recipe_overrides: [
        title: "Generated Post Index",
        empty_state: [
          title: "No generated posts yet",
          body: "Create a post to see the built-in collection recipe populate itself."
        ],
        fields: %{
          title: %{label: "Headline"},
          published_at: %{label: "Published"}
        },
        intents: %{
          create: %{label: "Compose Post"},
          read: %{label: "Open Generated", target: {:navigate, "/posts/generated/:id"}},
          update: %{label: "Revise"}
        },
        toolbar: [props: %{class: "justify-between items-center"}],
        content: [props: %{class: "shadow-sm"}]
      ]
    ]
  end
end
