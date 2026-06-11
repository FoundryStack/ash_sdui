defmodule SduiDemoWeb.Components.Layouts.TwoColumnLayout do
  use AshSDUI.Component,
    fragment: """
    fragment TwoColumnLayoutData on Layout {
      id
    }
    """

  use Phoenix.Component

  def render(assigns) do
    sidebar_children = Map.get(assigns.children || %{}, :sidebar, [])
    main_children = Map.get(assigns.children || %{}, :main, [])

    assigns =
      assigns
      |> Phoenix.Component.assign(:sidebar_children, sidebar_children)
      |> Phoenix.Component.assign(:main_children, main_children)

    ~H"""
    <div class="two-column-layout bg-base-100 rounded-box p-4">
      <div class="grid grid-cols-1 lg:grid-cols-4 gap-6" data-testid="two-column-layout">
        <aside class="sidebar lg:col-span-1 space-y-4">
          <%= for child <- @sidebar_children do %>
            <%= child %>
          <% end %>
        </aside>
        <main class="main-content lg:col-span-3">
          <%= for child <- @main_children do %>
            <%= child %>
          <% end %>
        </main>
      </div>
    </div>
    """
  end
end
