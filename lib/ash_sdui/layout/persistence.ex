defmodule AshSDUI.Layout.Persistence do
  @moduledoc """
  Compatibility wrapper for persisted layouts.

  Prefer `AshSDUI.Layout.save/3`, `AshSDUI.Layout.fetch/2`,
  `AshSDUI.Layout.load_nodes/2`, and `AshSDUI.Layout.publish/2`.
  """

  alias AshSDUI.Layout

  @deprecated "Use AshSDUI.Layout.save/3 instead"
  def persist(name, %Layout.Node{} = root, opts \\ []) do
    Layout.save(name, root, opts)
  end

  @deprecated "Use AshSDUI.Layout.fetch/2 or AshSDUI.Renderer.to_tree/2 instead"
  def load(name, opts \\ []) when is_binary(name) do
    name
    |> Layout.fetch(Keyword.put(opts, :source, :stored))
    |> case do
      {:ok, %Layout.LayoutDef{root: root}} -> {:ok, AshSDUI.Layout.Builder.to_tree(root)}
      error -> error
    end
  end

  @deprecated "Use AshSDUI.Layout.load_nodes/2 instead"
  def load_nodes(name, opts \\ []) do
    Layout.load_nodes(name, opts)
  end

  @deprecated "Use AshSDUI.Layout.publish/2 instead"
  def publish(name, opts \\ []) do
    Layout.publish(name, opts)
  end
end
