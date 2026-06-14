defmodule AshSDUI.LayoutPersistenceTest do
  use ExUnit.Case, async: false

  alias AshSDUI.Layout.Builder
  alias AshSDUI.Layout.Persistence
  alias AshSDUI.UINode

  setup do
    Ash.DataLayer.Ets.stop(UINode)
    Ash.DataLayer.Ets.stop(UINode.Version)

    :ok
  end

  test "persist/3 stores a builder tree as UINode records and load/2 restores it" do
    root =
      Builder.node("Layouts.TwoColumn@v1",
        children: [
          Builder.node("UserProfile.Header@v1", region: :sidebar, subject_id: "first"),
          Builder.node("Betting.ActiveBets@v1", region: :main, subject_id: "bet-1", order: 1)
        ]
      )

    assert {:ok, records} = persist("dashboard", root)
    assert length(records) == 3

    assert {:ok, tree} = load("dashboard", status: :draft)
    assert tree.component_name == "Layouts.TwoColumn@v1"
    assert Enum.map(tree.children, & &1.region) == [:sidebar, :main]
    assert Enum.at(tree.children, 0).subject_id == "first"
  end

  test "persist/3 replaces an existing layout by default" do
    first_root = Builder.node("One@v1")
    second_root = Builder.node("Two@v1")

    assert {:ok, _} = persist("replace-me", first_root)
    assert {:ok, _} = persist("replace-me", second_root)
    assert {:ok, tree} = load("replace-me", status: :draft)

    assert tree.component_name == "Two@v1"
    assert {:ok, nodes} = load_nodes("replace-me", status: :draft)
    assert length(nodes) == 1
  end

  test "publish/2 marks all nodes as published" do
    root =
      Builder.node("Root@v1",
        children: [
          Builder.node("Child@v1", subject_id: "second")
        ]
      )

    assert {:ok, _} = persist("publish-me", root)
    assert {:ok, published} = publish("publish-me")
    assert Enum.all?(published, &(&1.status == :published))
    assert {:ok, _tree} = load("publish-me")
  end

  defp persist(name, root, opts \\ []) do
    apply(Persistence, :persist, [name, root, opts])
  end

  defp load(name, opts \\ []) do
    apply(Persistence, :load, [name, opts])
  end

  defp load_nodes(name, opts) do
    apply(Persistence, :load_nodes, [name, opts])
  end

  defp publish(name, opts \\ []) do
    apply(Persistence, :publish, [name, opts])
  end
end
