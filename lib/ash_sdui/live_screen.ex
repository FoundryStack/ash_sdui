defmodule AshSDUI.LiveScreen do
  @moduledoc """
  Helpers for LiveViews that rebuild ephemeral layouts and their rendered trees.
  """

  import Phoenix.Component, only: [assign: 3]

  alias AshSDUI.Layout.Builder
  alias AshSDUI.Renderer

  @doc """
  Registers a layout, evicts its cache entry, renders it to a tree, and assigns
  both the layout name and tree onto the socket.
  """
  def assign_layout(socket, layout_name, root) do
    Builder.register(layout_name, root)
    AshSDUI.Cache.evict(layout_name)

    case Renderer.to_tree(layout_name) do
      {:ok, tree} ->
        socket
        |> assign(:__sdui_layout_name__, layout_name)
        |> assign(:__sdui_tree__, tree)

      {:error, reason} ->
        raise ArgumentError, "could not build layout #{inspect(layout_name)}: #{inspect(reason)}"
    end
  end
end
