defmodule AshSDUI.Components.SDUIRoot do
  @moduledoc false
  use Phoenix.Component

  def render(assigns) do
    tree = Map.get(assigns, :tree)

    if tree == nil do
      ~H"""
      <div class="sdui-error">UI graph not found.</div>
      """
    else
      # Support both old :override slot style and new overrides map
      overrides = build_override_map(assigns[:override] || assigns[:overrides] || [])
      assigns = assign(assigns, :_overrides, overrides) |> assign(:node, tree)

      ~H"""
      <.render_node node={@node} _overrides={@_overrides} />
      """
    end
  end

  defp render_node(%{node: nil} = assigns), do: ~H""

  defp render_node(%{node: node, _overrides: overrides} = assigns) do
    {module, subject} = resolve_component(node)
    children_by_region = pre_render_children(node.children || [], overrides)

    assigns =
      assigns
      |> assign(:component_module, module)
      |> assign(:subject, subject)
      |> assign(:children_by_region, children_by_region)

    ~H"""
    <%= if @component_module do %>
      <%= render_component(@component_module, @subject, @node.static_props, @node.region, @children_by_region) %>
    <% else %>
      <div
        data-sdui-component={@node.component_name}
        data-sdui-region={@node.region}
      >
        <%= for child <- (@node.children || []) do %>
          <.render_node node={child} _overrides={@_overrides} />
        <% end %>
      </div>
    <% end %>
    """
  end

  defp render_component(module, subject, props, region, children) do
    assigns = %{
      subject: subject,
      props: props,
      region: region,
      children: children,
      __changed__: nil
    }

    case module.render(assigns) do
      result when is_binary(result) -> Phoenix.HTML.raw(result)
      result -> result
    end
  end

  defp resolve_component(node) do
    case AshSDUI.Registry.lookup(node.component_name) do
      {:ok, entry} ->
        subject = AshSDUI.Calculations.ResolveSubject.resolve(node)
        {entry.module, subject}

      {:error, :not_found} ->
        {nil, nil}
    end
  end

  defp build_override_map(overrides) when is_list(overrides) do
    Map.new(overrides, fn
      %{node_id: node_id} -> {node_id, true}
      other -> {other, true}
    end)
  end

  defp build_override_map(overrides) when is_map(overrides) do
    overrides
  end

  defp pre_render_children(children, overrides) do
    children
    |> Enum.group_by(& &1.region)
    |> Map.new(fn {region, nodes} ->
      rendered =
        nodes
        |> Enum.sort_by(& &1.order)
        |> Enum.map(&render_child_node(&1, overrides))

      {region, rendered}
    end)
  end

  defp render_child_node(node, overrides) do
    {module, subject} = resolve_component(node)
    children_by_region = pre_render_children(node.children || [], overrides)

    if module do
      module.render(%{
        subject: subject,
        props: node.static_props,
        region: node.region,
        children: children_by_region,
        __changed__: nil
      })
    else
      html_placeholder(node, overrides)
    end
  end

  defp html_placeholder(node, overrides) do
    children_html =
      (node.children || [])
      |> Enum.sort_by(& &1.order)
      |> Enum.map(fn child ->
        content = render_child_node(child, overrides)

        case content do
          content when is_binary(content) ->
            content

          content ->
            # Convert Rendered struct to string
            Phoenix.HTML.Safe.to_iodata(content) |> IO.iodata_to_binary()
        end
      end)
      |> Enum.join("")

    ~s"""
    <div data-sdui-component="#{node.component_name}" data-sdui-region="#{node.region}">
    #{children_html}
    </div>
    """
    |> Phoenix.HTML.raw()
  end
end
