defmodule AshSDUI.RenderingTest do
  use ExUnit.Case, async: false

  alias AshSDUI.Layout
  alias AshSDUI.Layout.Builder
  alias AshSDUI.Renderer
  alias AshSDUI.Renderer.TreeNode
  alias AshSDUI.UINode

  setup do
    AshSDUI.Cache.start_link()
    AshSDUI.Test.TestLayout.init_layouts()
    Ash.DataLayer.Ets.stop(UINode)
    Ash.DataLayer.Ets.stop(UINode.Version)
    :ok
  end

  describe "to_tree/1 with code-based layout" do
    test "returns nested TreeNode struct for known layout" do
      assert {:ok, %TreeNode{} = root} = Renderer.to_tree("test-dashboard")
      assert root.component_name == "Layouts.TwoColumn@v1"
    end

    test "root node has children" do
      {:ok, root} = Renderer.to_tree("test-dashboard")
      assert length(root.children) == 2
    end

    test "child nodes have correct component names" do
      {:ok, root} = Renderer.to_tree("test-dashboard")
      components = Enum.map(root.children, & &1.component_name)
      assert "UserProfile.Header@v1" in components
      assert "Betting.ActiveBets@v1" in components
    end

    test "children are sorted by order" do
      {:ok, root} = Renderer.to_tree("test-dashboard")
      orders = Enum.map(root.children, & &1.order)
      assert orders == Enum.sort(orders)
    end

    test "returns error for unknown layout" do
      assert {:error, {:not_found, "nonexistent"}} = Renderer.to_tree("nonexistent")
    end

    test "returns nested TreeNode struct for stored layout names" do
      root =
        Builder.node("Stored.Root@v1",
          children: [
            Builder.node("Stored.Child@v1", region: :main)
          ]
        )

      assert {:ok, _records} = Layout.save("stored-render", root, status: :published)
      assert {:ok, %TreeNode{} = tree} = Renderer.to_tree("stored-render")

      assert tree.component_name == "Stored.Root@v1"
      assert hd(tree.children).component_name == "Stored.Child@v1"
    end

    test "keeps layout definitions and rendered trees as distinct shapes" do
      Layout.register("definition-boundary", Builder.node("Boundary.Root@v1"))

      assert {:ok, layout} = Layout.fetch("definition-boundary")
      assert %AshSDUI.Layout.Node{} = layout.root

      assert {:ok, tree} = Renderer.to_tree("definition-boundary")
      assert %TreeNode{} = tree
      assert tree.component_name == layout.root.component
    end

    test "passes renderer options from use AshSDUI mount" do
      defmodule StoredLayoutLive do
        use AshSDUI, lookup: {:static, "stored-live"}, source: :stored, status: :draft
      end

      root = Builder.node("Stored.Live@v1")

      assert {:ok, _records} = Layout.save("stored-live", root, status: :draft)
      assert {:ok, socket} = StoredLayoutLive.mount(%{}, %{}, %Phoenix.LiveView.Socket{})

      assert socket.assigns.__sdui_tree__.component_name == "Stored.Live@v1"
    end
  end

  describe "to_tree/1 with flat record list" do
    test "builds tree from records with parent-child structure" do
      records = [
        %{
          id: "root",
          component_name: "Root@v1",
          parent_id: nil,
          region: :default,
          order: 0,
          static_props: %{},
          subject_resource: nil,
          subject_id: nil
        },
        %{
          id: "child1",
          component_name: "Child@v1",
          parent_id: "root",
          region: :main,
          order: 0,
          static_props: %{},
          subject_resource: nil,
          subject_id: nil
        }
      ]

      assert {:ok, %TreeNode{} = root} = Renderer.to_tree(records)
      assert root.id == "root"
      assert length(root.children) == 1
      assert hd(root.children).id == "child1"
    end

    test "returns error when no root node found" do
      records = [
        %{
          id: "child1",
          component_name: "Child@v1",
          parent_id: "missing",
          region: :main,
          order: 0,
          static_props: %{},
          subject_resource: nil,
          subject_id: nil
        }
      ]

      assert {:error, :no_root_node} = Renderer.to_tree(records)
    end
  end
end
