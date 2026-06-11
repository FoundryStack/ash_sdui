defmodule SduiDemoWeb.Components.DashboardLayout do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <%= if @children[:header] do %>
        <div class="sticky top-0 z-50">
          <%= render_slot(@children[:header]) %>
        </div>
      <% end %>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-12 gap-6">
          <%= if @children[:sidebar] do %>
            <div class="col-span-12 md:col-span-3">
              <%= render_slot(@children[:sidebar]) %>
            </div>
            <div class="col-span-12 md:col-span-9">
              <%= render_slot(@children[:content]) %>
            </div>
          <% else %>
            <div class="col-span-12">
              <%= render_slot(@children[:content]) %>
            </div>
          <% end %>
        </div>
      </div>

      <%= if @children[:footer] do %>
        <div class="border-t border-gray-200 bg-white mt-8">
          <%= render_slot(@children[:footer]) %>
        </div>
      <% end %>
    </div>
    """
  end
end
