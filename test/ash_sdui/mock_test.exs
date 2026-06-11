defmodule AshSDUI.MockTest do
  use ExUnit.Case, async: true

  alias AshSDUI.Mock
  alias AshSDUI.Renderer.TreeNode

  describe "tree_node/2" do
    test "creates a minimal tree node with defaults" do
      node = Mock.tree_node("Card@v1")

      assert node.component_name == "Card@v1"
      assert node.region == :default
      assert node.order == 0
      assert node.children == []
      assert is_binary(node.id)
      assert node.static_props == %{}
    end

    test "accepts custom id" do
      custom_id = "my-node-id"
      node = Mock.tree_node("Card@v1", id: custom_id)

      assert node.id == custom_id
    end

    test "accepts custom static_props" do
      props = %{"title" => "Hello", "variant" => "primary"}
      node = Mock.tree_node("Card@v1", static_props: props)

      assert node.static_props == props
    end

    test "accepts subject_resource and subject_id" do
      node = Mock.tree_node("Card@v1",
        subject_resource: "MyApp.Player",
        subject_id: "player-123"
      )

      assert node.subject_resource == "MyApp.Player"
      assert node.subject_id == "player-123"
    end

    test "accepts region and order" do
      node = Mock.tree_node("Card@v1", region: :sidebar, order: 2)

      assert node.region == :sidebar
      assert node.order == 2
    end

    test "accepts children" do
      child1 = Mock.tree_node("Text@v1")
      child2 = Mock.tree_node("Badge@v1")
      node = Mock.tree_node("Card@v1", children: [child1, child2])

      assert node.children == [child1, child2]
      assert length(node.children) == 2
    end

    test "returns a TreeNode struct" do
      node = Mock.tree_node("Card@v1")

      assert is_struct(node, TreeNode)
    end
  end

  describe "from_resource/2" do
    setup do
      # Create a test resource with sdui annotation
      defmodule TestPlayer do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        sdui do
          default_component "Player.Card@v1"
        end
      end

      {:ok, resource: TestPlayer}
    end

    test "builds tree node from resource with default_component", %{resource: resource} do
      node = Mock.from_resource(resource)

      assert node.component_name == "Player.Card@v1"
      assert node.subject_resource == to_string(resource)
      assert node.subject_id == "first"
    end

    test "accepts custom subject_id", %{resource: resource} do
      node = Mock.from_resource(resource, subject_id: "player-42")

      assert node.subject_id == "player-42"
    end

    test "accepts custom component_name override", %{resource: resource} do
      node = Mock.from_resource(resource, component_name: "Custom.Component@v2")

      assert node.component_name == "Custom.Component@v2"
    end

    test "raises if no default_component and no override" do
      defmodule TestResourceNoComponent do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]
        sdui do
        end
      end

      assert_raise ArgumentError, ~r/Pass :component_name or annotate resource/, fn ->
        Mock.from_resource(TestResourceNoComponent)
      end
    end
  end
end
