defmodule AshSDUI.Components.GenericView do
  @moduledoc """
  Minimal shell component used by the generic recipe.

  It renders named child regions while keeping the root node generic enough for
  app-level overrides and custom design systems.
  """

  use Phoenix.Component

  AshSDUI.Registry.register("AshSDUI.GenericView@v1", __MODULE__, %{
    fragment: "",
    subject_types: []
  })

  def __ash_sdui_component_name__, do: "AshSDUI.GenericView@v1"
  def __ash_sdui_fragment__, do: ""
  def __ash_sdui_subject_types__, do: []

  attr(:props, :map, default: %{})
  attr(:children, :map, default: %{})

  def render(assigns) do
    ~H"""
    <section class={["space-y-6", Map.get(@props, :class)]} data-testid="generic-view">
      <header :if={Map.get(@props, :title) || Map.has_key?(@children, :toolbar)} class="space-y-4">
        <div :if={Map.get(@props, :title)} class="space-y-1">
          <h1 class="text-2xl font-semibold">{Map.get(@props, :title)}</h1>
        </div>
        <%= for child <- Map.get(@children, :toolbar, []) do %>
          {child}
        <% end %>
      </header>

      <main class="space-y-4">
        <%= for child <- Map.get(@children, :content, []) do %>
          {child}
        <% end %>

        <%= for child <- Map.get(@children, :default, []) do %>
          {child}
        <% end %>
      </main>
    </section>
    """
  end
end
