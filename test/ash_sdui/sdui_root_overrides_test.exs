defmodule AshSDUI.SDUIRootOverridesTest do
  use ExUnit.Case, async: true

  alias AshSDUI.Mock
  alias AshSDUI.Components.SDUIRoot

  defmodule OverrideCard do
    use Phoenix.Component

    def render(assigns) do
      ~H"""
      <div class="override-card" data-testid="override-card">
        <%= @props["headline"] %>
      </div>
      """
    end
  end

  setup do
    :persistent_term.put({AshSDUI.Registry, :components}, %{})

    AshSDUI.Registry.register(
      "Card@v1",
      OverrideCard,
      %{fragment: "fragment X on Test { id }", subject_types: ["Test"]}
    )

    AshSDUI.Registry.register(
      "CardOverride@v1",
      OverrideCard,
      %{fragment: "fragment X on Test { id }", subject_types: ["Test"]}
    )

    :ok
  end

  describe "SDUIRoot with slot overrides" do
    test "renders without overrides" do
      tree =
        Mock.tree_node("Card@v1",
          children: [
            Mock.tree_node("Title@v1"),
            Mock.tree_node("Body@v1")
          ]
        )

      result = render_component(SDUIRoot, %{tree: tree})

      # Should render successfully without overrides
      assert is_binary(result) or is_struct(result, Phoenix.LiveView.Rendered)
    end

    test "renders with override slots at root level" do
      tree = Mock.tree_node("Card@v1", id: "root-card")

      result =
        render_component(SDUIRoot, %{
          tree: tree,
          override: [%{node_id: "root-card"}]
        })

      assert is_binary(result) or is_struct(result, Phoenix.LiveView.Rendered)
    end

    test "renders with override slots at child level" do
      child_id = "child-node-id"

      tree =
        Mock.tree_node("Panel@v1",
          children: [
            Mock.tree_node("Card@v1", id: child_id)
          ]
        )

      result =
        render_component(SDUIRoot, %{
          tree: tree,
          override: [%{node_id: child_id}]
        })

      assert is_binary(result) or is_struct(result, Phoenix.LiveView.Rendered)
    end

    test "renders with multiple override slots" do
      tree =
        Mock.tree_node("Layout@v1",
          children: [
            Mock.tree_node("Header@v1", id: "header"),
            Mock.tree_node("Body@v1", id: "body"),
            Mock.tree_node("Footer@v1", id: "footer")
          ]
        )

      result =
        render_component(SDUIRoot, %{
          tree: tree,
          override: [
            %{node_id: "header"},
            %{node_id: "footer"}
          ]
        })

      assert is_binary(result) or is_struct(result, Phoenix.LiveView.Rendered)
    end

    test "override map can replace component and merge props by node id" do
      tree =
        Mock.tree_node("Card@v1",
          id: "root-card",
          static_props: %{"headline" => "Original"}
        )

      result =
        render_component(SDUIRoot, %{
          tree: tree,
          overrides: %{
            "root-card" => %{
              component: "CardOverride@v1",
              props: %{"headline" => "Overridden"}
            }
          }
        })

      html = rendered_to_string(result)

      assert html =~ "override-card"
      assert html =~ "Overridden"
      refute html =~ "Original"
    end

    test "override map can skip a child node" do
      tree =
        Mock.tree_node("UnknownRoot@v1",
          children: [
            Mock.tree_node("Card@v1",
              id: "keep-me",
              static_props: %{"headline" => "Visible"}
            ),
            Mock.tree_node("Card@v1",
              id: "skip-me",
              static_props: %{"headline" => "Hidden"}
            )
          ]
        )

      result =
        render_component(SDUIRoot, %{
          tree: tree,
          overrides: %{
            "skip-me" => false
          }
        })

      html = rendered_to_string(result)

      assert html =~ "Visible"
      refute html =~ "Hidden"
    end
  end

  defp render_component(module, assigns) do
    # Helper to render a Phoenix component for testing
    assigns = Map.put(assigns, :__changed__, nil)
    module.render(assigns)
  end

  defp rendered_to_string(content) when is_binary(content), do: content

  defp rendered_to_string(content) do
    Phoenix.HTML.Safe.to_iodata(content) |> IO.iodata_to_binary()
  end
end
