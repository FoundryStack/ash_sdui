defmodule SduiDemoWeb.Storybook.Components.PostUIFiltered do
  @moduledoc """
  Generated collection story showing a filtered query state.
  """

  use AshSDUI.Storybook,
    ui: SduiDemo.UI.Resources.PostUI,
    view: :index,
    recipe: :collection,
    params: %{"search" => "Storybook", "sort" => "-published_at", "offset" => "10"},
    bindings: %{
      collection: [
        %{
          id: "story-post-filtered-1",
          title: "Storybook filtered result",
          body: "A filtered result row rendered through the generated collection view.",
          published_at: ~U[2026-06-15 09:00:00Z]
        }
      ]
    }
end
