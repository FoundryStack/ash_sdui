defmodule SduiDemoWeb.Live.DemoLive do
  use SduiDemoWeb, :live_view

  @features [
    %{
      icon: "Recipe",
      title: "Screen recipes",
      desc:
        "Start from Ash metadata, then let an app-side recipe shape an editorial page without throwing away the generated flow."
    },
    %{
      icon: "Generated",
      title: "Override-first path",
      desc:
        "The same metadata can also stay on the built-in recipe path, with copy, labels, and layout polish coming from recipe_overrides alone."
    },
    %{
      icon: "LiveView",
      title: "LiveResource engine",
      desc:
        "List, show, create, edit, validate, and submit stay conventional, so custom UI work lands on top of the same engine."
    },
    %{
      icon: "Theme",
      title: "Storybook parity",
      desc:
        "The demo app and Storybook now share the same Tailwind and DaisyUI path, which keeps component previews visually honest."
    },
    %{
      icon: "Actions",
      title: "Ash-aware actions",
      desc:
        "Default resource actions still come from SDUI metadata, but the app decides where they live and how far to customize the surface."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :features, @features)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.demo_page_layout features={@features} />
    """
  end

  defp demo_page_layout(assigns) do
    SduiDemoWeb.Components.Layouts.DemoPageLayout.render(assigns)
  end
end
