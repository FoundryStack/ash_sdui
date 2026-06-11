defmodule SduiDemoWeb.Components.PageHeader do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="bg-white border-b border-gray-200 shadow-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div class="flex justify-between items-center">
          <div>
            <h1 class="text-3xl font-bold text-gray-900">
              <%= @props["title"] || "Page" %>
            </h1>
            <%= if @props["subtitle"] do %>
              <p class="mt-2 text-gray-600"><%= @props["subtitle"] %></p>
            <% end %>
          </div>
          <%= if @children[:actions] do %>
            <div class="flex gap-3">
              <%= render_slot(@children[:actions]) %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
