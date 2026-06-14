defmodule SduiDemoWeb.Components.ResourceActions do
  @moduledoc false

  use Phoenix.Component

  attr(:resource, :atom, required: true)
  attr(:subject, :any, default: nil)
  attr(:actions, :list, default: nil)
  attr(:overrides, :map, default: %{})
  attr(:placement, :atom, default: nil)
  attr(:class, :string, default: nil)

  def render(assigns) do
    AshSDUI.Components.ResourceActions.render(assigns)
  end
end
