defmodule SduiDemoWeb.Components.ActionButton do
  use AshSDUI.Component,
    fragment: """
    fragment ActionButtonData on Action {
      label
      url
    }
    """

  use Phoenix.Component

  def render(assigns) do
    props = assigns.props || %{}
    variant = Map.get(props, "variant", "btn-outline")
    assigns = assign(assigns, :props, props) |> assign(:variant, variant)
    ~H"""
    <a href={Map.get(@props, "url", "#")} class={["btn action-button", @variant]} data-testid="action-button">
      <%= Map.get(@props, "label", "Click") %>
    </a>
    """
  end
end
