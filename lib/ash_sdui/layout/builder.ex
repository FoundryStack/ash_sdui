defmodule AshSDUI.Layout.Builder do
  @moduledoc """
  Small helpers for building and registering code-defined layouts.

  The goal is to keep layout authoring declarative without hand-building
  `%AshSDUI.Layout.Node{}` structs for every leaf.
  """

  alias AshSDUI.Layout
  alias AshSDUI.Renderer.TreeNode
  alias AshSDUI.Resource.Info

  @doc "Registers a layout and returns its name."
  def register(name, %Layout.Node{} = root) when is_binary(name) do
    Layout.register(name, %Layout.LayoutDef{name: name, root: root})
    name
  end

  @doc "Builds a generic layout node."
  def node(component, opts \\ []) when is_binary(component) do
    %Layout.Node{
      id:
        Keyword.get_lazy(opts, :id, fn ->
          default_id(component, Keyword.get(opts, :subject_id))
        end),
      component: component,
      region: Keyword.get(opts, :region, :default),
      order: Keyword.get(opts, :order, 0),
      subject_resource: normalize_resource(Keyword.get(opts, :subject_resource)),
      subject_id: normalize_subject_id(Keyword.get(opts, :subject_id)),
      static_props: Keyword.get(opts, :static_props, %{}),
      children: Keyword.get(opts, :children, [])
    }
  end

  @doc """
  Builds a node from an annotated resource or standalone UI module.

  Uses the resource's `default_component` unless `:component` is provided.
  """
  def resource(resource_or_ui, opts \\ []) do
    component =
      Keyword.get(opts, :component) ||
        Info.default_component(resource_or_ui) ||
        raise ArgumentError, "missing default_component for #{inspect(resource_or_ui)}"

    subject_resource = Keyword.get(opts, :subject_resource, Info.for_resource(resource_or_ui))
    subject_id = Keyword.get(opts, :subject_id, "first")

    component
    |> node(
      id: Keyword.get(opts, :id),
      region: Keyword.get(opts, :region, :default),
      order: Keyword.get(opts, :order, 0),
      subject_resource: subject_resource,
      subject_id: subject_id,
      children: Keyword.get(opts, :children, [])
    )
  end

  @doc """
  Builds one node per record using the resource's default component.
  """
  def resources(resource_or_ui, records, opts \\ []) when is_list(records) do
    region = Keyword.get(opts, :region, :default)
    children_fun = Keyword.get(opts, :children, fn _, _ -> [] end)
    id_prefix = Keyword.get(opts, :id_prefix, default_prefix(resource_or_ui))

    records
    |> Enum.with_index()
    |> Enum.map(fn {record, index} ->
      resource(resource_or_ui,
        id: "#{id_prefix}-#{record.id}",
        region: region,
        order: index,
        subject_id: record.id,
        children: children_fun.(record, index)
      )
    end)
  end

  @doc "Converts a layout node into a renderable `%AshSDUI.Renderer.TreeNode{}`."
  def to_tree(%Layout.Node{} = node) do
    %TreeNode{
      id: node.id,
      component_name: node.component,
      static_props: node.static_props || %{},
      subject_resource: node.subject_resource,
      subject_id: node.subject_id,
      region: node.region,
      order: node.order,
      children:
        node.children
        |> List.wrap()
        |> Enum.sort_by(& &1.order)
        |> Enum.map(&to_tree/1)
    }
  end

  defp default_prefix(resource_or_ui) do
    resource_or_ui
    |> Info.for_resource()
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp default_id(component, nil),
    do: component |> String.replace(~r/[^a-zA-Z0-9]+/, "-") |> String.downcase()

  defp default_id(component, subject_id), do: "#{default_id(component, nil)}-#{subject_id}"

  defp normalize_resource(nil), do: nil
  defp normalize_resource(resource) when is_binary(resource), do: resource
  defp normalize_resource(resource), do: to_string(resource)

  defp normalize_subject_id(nil), do: nil
  defp normalize_subject_id(subject_id) when is_binary(subject_id), do: subject_id
  defp normalize_subject_id(subject_id), do: to_string(subject_id)
end
