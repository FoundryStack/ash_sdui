defmodule SduiDemoWeb.Storybook.Components.StatusBadge do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &AshSDUI.Components.StatusBadge.render/1

  def variations do
    [
      %Variation{id: :review, attributes: %{status: "review", variant: :warning}},
      %Variation{id: :approved, attributes: %{status: "approved", variant: :success}},
      %Variation{id: :paused, attributes: %{status: "paused", variant: :info}}
    ]
  end
end
