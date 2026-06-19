defmodule SduiDemoWeb.Live.GeneratedPostShowLive do
  use AshSDUI.LiveResource,
    ui: SduiDemo.UI.Resources.PostUI,
    view: :show,
    domain: SduiDemo.Blog

  def ash_sdui_view_opts(_mode, _params, _session, _socket) do
    [
      recipe: :detail,
      recipe_overrides: [
        title: "Generated Post Detail",
        intents: %{
          read: %{label: "Open Generated"},
          update: %{label: "Revise Post"}
        },
        toolbar: [props: %{class: "justify-end"}],
        content: [props: %{class: "rounded-box border border-base-300 bg-base-100 p-4 shadow-sm"}]
      ]
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-6xl px-4 py-10 sm:px-6">
      <%= AshSDUI.LiveResource.render_resource(assigns) %>
    </div>
    """
  end
end
