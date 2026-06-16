defmodule SduiDemoWeb.Storybook.Layouts.PersistedLayoutShowcase do
  use PhoenixStorybook.Story, :component
  alias PhoenixStorybook.Stories.Variation

  def function, do: &AshSDUI.Components.SDUIRoot.render/1

  def variations do
    [
      %Variation{
        id: :default,
        description:
          "A stored-layout-equivalent tree authored as layout nodes and rendered through SDUIRoot",
        attributes: %{
          tree: SduiDemo.UI.DemoLayouts.persisted_root() |> AshSDUI.Layout.Builder.to_tree()
        }
      }
    ]
  end
end
