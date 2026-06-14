defmodule AshSDUI.Mock do
  @moduledoc """
  Utilities for building test fixtures and mock trees without manual TreeNode construction.

  ## Examples

      # Simple node
      node = AshSDUI.Mock.tree_node("Card@v1")

      # Node with children
      parent = AshSDUI.Mock.tree_node("Panel@v1", children: [
        AshSDUI.Mock.tree_node("Header@v1"),
        AshSDUI.Mock.tree_node("Body@v1")
      ])

      # From a resource
      tree = AshSDUI.Mock.from_resource(MyApp.Player, subject_id: "player-42")
  """

  alias AshSDUI.Renderer.TreeNode

  @doc """
  Builds a TreeNode with sensible defaults.

  ## Options

  - `:id` — UUID string, generated if omitted
  - `:static_props` — map, default `%{}`
  - `:subject_resource` — string resource name, optional
  - `:subject_id` — string record ID, optional
  - `:region` — atom region name, default `:default`
  - `:order` — non-negative integer, default `0`
  - `:children` — list of TreeNode structs, default `[]`
  """
  def tree_node(component_name, opts \\ []) do
    %TreeNode{
      id: Keyword.get(opts, :id, Ecto.UUID.generate()),
      component_name: component_name,
      static_props: Keyword.get(opts, :static_props, %{}),
      subject_resource: Keyword.get(opts, :subject_resource),
      subject_id: Keyword.get(opts, :subject_id),
      region: Keyword.get(opts, :region, :default),
      order: Keyword.get(opts, :order, 0),
      children: Keyword.get(opts, :children, [])
    }
  end

  @doc """
  Builds a TreeNode from a resource with SDUI annotation.

  Reads `:default_component` from the resource's `sdui` block and wraps it in a TreeNode
  pointing to the resource as the subject.

  ## Options

  - `:subject_id` — string record ID, default `"first"`
  - `:component_name` — override the resource's default component name

  ## Raises

  - `ArgumentError` if resource has no `:default_component` and `:component_name` is not passed
  """
  def from_resource(resource, opts \\ []) do
    component_name =
      Keyword.get(opts, :component_name) ||
        AshSDUI.Resource.Info.default_component(resource) ||
        raise ArgumentError,
              "Pass :component_name or annotate resource with default_component"

    # for standalone UI modules, subject_resource is the domain resource, not the UI module
    domain_resource = AshSDUI.Resource.Info.for_resource(resource)

    tree_node(component_name,
      subject_resource: to_string(domain_resource),
      subject_id: Keyword.get(opts, :subject_id, "first")
    )
  end
end
