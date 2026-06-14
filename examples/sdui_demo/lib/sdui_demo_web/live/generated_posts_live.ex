defmodule SduiDemoWeb.Live.GeneratedPostsLive do
  use AshSDUI.LiveResource,
    resource: SduiDemo.UI.Resources.PostUI,
    screen: :index,
    domain: SduiDemo.Blog

  def ash_sdui_screen_opts(_mode, _params, _session, _socket) do
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
        actions: %{
          create: %{label: "Compose Post"},
          read: %{label: "Open"},
          update: %{label: "Revise"}
        },
        toolbar: [props: %{class: "justify-between items-center"}],
        content: [props: %{class: "shadow-sm"}]
      ]
    ]
  end
end
