defmodule SduiDemoWeb.Storybook.Components.PostUIShow do
  @moduledoc """
  Generated detail story for the PostUI view.
  """

  use AshSDUI.Storybook,
    ui: SduiDemo.UI.Resources.PostUI,
    view: :show,
    bindings: %{
      record: %{
        id: "story-post-show-1",
        title: "Generated detail view",
        body: "This story exercises the built-in detail recipe path.",
        published_at: ~U[2026-06-14 09:00:00Z]
      }
    }
end
