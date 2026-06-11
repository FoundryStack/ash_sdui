defmodule AshSDUI.SDUIRootOverridesTest do
  use ExUnit.Case, async: true

  alias AshSDUI.Mock
  alias AshSDUI.Components.SDUIRoot

  describe "SDUIRoot with slot overrides" do
    test "renders without overrides" do
      tree = Mock.tree_node("Card@v1", children: [
        Mock.tree_node("Title@v1"),
        Mock.tree_node("Body@v1")
      ])

      result = render_component(SDUIRoot, %{tree: tree})

      # Should render successfully without overrides
      assert is_binary(result) or is_struct(result, Phoenix.LiveView.Rendered)
    end

    test "renders with override slots at root level" do
      tree = Mock.tree_node("Card@v1", id: "root-card")

      result = render_component(SDUIRoot, %{
        tree: tree,
        override: [%{node_id: "root-card"}]
      })

      assert is_binary(result) or is_struct(result, Phoenix.LiveView.Rendered)
    end

    test "renders with override slots at child level" do
      child_id = "child-node-id"
      tree = Mock.tree_node("Panel@v1", children: [
        Mock.tree_node("Card@v1", id: child_id)
      ])

      result = render_component(SDUIRoot, %{
        tree: tree,
        override: [%{node_id: child_id}]
      })

      assert is_binary(result) or is_struct(result, Phoenix.LiveView.Rendered)
    end

    test "renders with multiple override slots" do
      tree = Mock.tree_node("Layout@v1", children: [
        Mock.tree_node("Header@v1", id: "header"),
        Mock.tree_node("Body@v1", id: "body"),
        Mock.tree_node("Footer@v1", id: "footer")
      ])

      result = render_component(SDUIRoot, %{
        tree: tree,
        override: [
          %{node_id: "header"},
          %{node_id: "footer"}
        ]
      })

      assert is_binary(result) or is_struct(result, Phoenix.LiveView.Rendered)
    end
  end

  defp render_component(module, assigns) do
    # Helper to render a Phoenix component for testing
    assigns = Map.put(assigns, :__changed__, nil)
    module.render(assigns)
  end
end
