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

      assigns =
        assigns
        |> assign(:_overrides, overrides)
        |> assign(:_resolve_opts, resolve_opts(assigns))
        |> assign(:node, tree)

      ~H"""
      <.render_node node={@node} _overrides={@_overrides} _resolve_opts={@_resolve_opts} />
      """
    end
  end

  defp render_node(%{node: nil} = assigns), do: ~H""

  defp render_node(
         %{node: raw_node, _overrides: overrides, _resolve_opts: resolve_opts} = assigns
       ) do
    {node, override} = apply_override(raw_node, overrides)
    {module, subject} = resolve_component(node, override, resolve_opts)
    children_by_region = pre_render_children(node.children || [], overrides, resolve_opts)
    runtime_assigns = runtime_assigns(node, resolve_opts)

    assigns =
      assigns
      |> assign(:component_module, module)
      |> assign(:subject, subject)
      |> assign(:props, merged_props(node, override))
      |> assign(:node, node)
      |> assign(:children_by_region, children_by_region)
      |> assign(:runtime_assigns, runtime_assigns)

    ~H"""
    <%= if @component_module do %>
      <%= render_component(@component_module, @subject, @props, @node.region, @children_by_region, @runtime_assigns) %>
    <% else %>
      <div
        data-sdui-component={@node.component_name}
        data-sdui-region={@node.region}
        data-sdui-binding={@node.binding}
        data-sdui-state-key={normalize_data_attr(@node.state_key)}
        data-sdui-variant={@node.variant}
      >
        <%= for child <- Enum.reject(@node.children || [], &skip_node?(&1, @_overrides)) do %>
          <.render_node node={child} _overrides={@_overrides} _resolve_opts={@_resolve_opts} />
        <% end %>
      </div>
    <% end %>
    """
  end

  defp render_component(module, subject, props, region, children, runtime_assigns) do
    assigns =
      props
      |> Map.new()
      |> Map.merge(%{
        subject: subject,
        props: props,
        region: region,
        children: children,
        node: runtime_assigns.node,
        view: runtime_assigns.view,
        bindings: runtime_assigns.bindings,
        state: runtime_assigns.state,
        context: runtime_assigns.context,
        binding_name: runtime_assigns.binding_name,
        bound_value: runtime_assigns.bound_value,
        refresh_meta: runtime_assigns.refresh_meta,
        state_key: runtime_assigns.state_key,
        state_slice: runtime_assigns.state_slice,
        node_refresh: runtime_assigns.node_refresh,
        node_variant: runtime_assigns.node_variant,
        __changed__: nil
      })

    case module.render(assigns) do
      result when is_binary(result) -> Phoenix.HTML.raw(result)
      result -> result
    end
  end

  defp resolve_component(node, override, resolve_opts) do
    case component_module(node, override) do
      {:ok, module} ->
        subject =
          Map.get(
            override,
            :subject,
            AshSDUI.Calculations.ResolveSubject.resolve(node, resolve_opts)
          )

        {module, subject}

      :error ->
        {nil, nil}
    end
  end

  defp component_module(node, override) do
    component_name =
      Map.get(override, :component_name) ||
        Map.get(override, :component) ||
        node.component_name

    case AshSDUI.Registry.lookup(component_name) do
      {:ok, entry} ->
        {:ok, entry.module}

      {:error, :not_found} ->
        :error
    end
  end

  defp build_override_map(overrides) when is_list(overrides) do
    Map.new(overrides, fn
      %{node_id: node_id} = override -> {node_id, Map.delete(override, :node_id)}
      {key, value} -> {key, normalize_override(value)}
      other -> {other, %{}}
    end)
  end

  defp build_override_map(overrides) when is_map(overrides) do
    Map.new(overrides, fn {key, value} -> {key, normalize_override(value)} end)
  end

  defp pre_render_children(children, overrides, resolve_opts) do
    children
    |> Enum.group_by(& &1.region)
    |> Map.new(fn {region, nodes} ->
      rendered =
        nodes
        |> Enum.sort_by(& &1.order)
        |> Enum.reject(&skip_node?(&1, overrides))
        |> Enum.map(&render_child_node(&1, overrides, resolve_opts))

      {region, rendered}
    end)
  end

  defp render_child_node(raw_node, overrides, resolve_opts) do
    {node, override} = apply_override(raw_node, overrides)
    {module, subject} = resolve_component(node, override, resolve_opts)
    children_by_region = pre_render_children(node.children || [], overrides, resolve_opts)
    props = merged_props(node, override)
    runtime_assigns = runtime_assigns(node, resolve_opts)

    if module do
      module.render(
        props
        |> Map.new()
        |> Map.merge(%{
          subject: subject,
          props: props,
          region: node.region,
          children: children_by_region,
          node: runtime_assigns.node,
          view: runtime_assigns.view,
          bindings: runtime_assigns.bindings,
          state: runtime_assigns.state,
          context: runtime_assigns.context,
          binding_name: runtime_assigns.binding_name,
          bound_value: runtime_assigns.bound_value,
          refresh_meta: runtime_assigns.refresh_meta,
          state_key: runtime_assigns.state_key,
          state_slice: runtime_assigns.state_slice,
          node_refresh: runtime_assigns.node_refresh,
          node_variant: runtime_assigns.node_variant,
          __changed__: nil
        })
      )
    else
      html_placeholder(node, overrides, resolve_opts)
    end
  end

  defp html_placeholder(node, overrides, resolve_opts) do
    children_html =
      (node.children || [])
      |> Enum.sort_by(& &1.order)
      |> Enum.reject(&skip_node?(&1, overrides))
      |> Enum.map(fn child ->
        content = render_child_node(child, overrides, resolve_opts)

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
    <div data-sdui-component="#{node.component_name}" data-sdui-region="#{node.region}" data-sdui-binding="#{node.binding}" data-sdui-state-key="#{normalize_data_attr(node.state_key)}" data-sdui-variant="#{node.variant}">
    #{children_html}
    </div>
    """
    |> Phoenix.HTML.raw()
  end

  defp apply_override(node, overrides) do
    override = Map.get(overrides, node.id, Map.get(overrides, node.component_name, %{}))
    children = override_children(node.children || [], override)

    updated_node =
      node
      |> Map.put(
        :component_name,
        Map.get(override, :component_name, Map.get(override, :component, node.component_name))
      )
      |> Map.put(:static_props, merged_props(node, override))
      |> Map.put(:subject_resource, Map.get(override, :subject_resource, node.subject_resource))
      |> Map.put(
        :subject_id,
        normalize_subject_id(Map.get(override, :subject_id, node.subject_id))
      )
      |> Map.put(:refresh, Map.get(override, :refresh, Map.get(node, :refresh)))
      |> Map.put(:binding, Map.get(override, :binding, Map.get(node, :binding)))
      |> Map.put(:variant, Map.get(override, :variant, Map.get(node, :variant)))
      |> Map.put(:state_key, Map.get(override, :state_key, Map.get(node, :state_key)))
      |> Map.put(:children, children)

    {updated_node, override}
  end

  defp merged_props(node, override) do
    node.static_props
    |> Kernel.||(%{})
    |> maybe_put_prop(:variant, Map.get(node, :variant))
    |> Map.merge(normalize_props(Map.get(override, :props, %{})))
  end

  defp override_children(children, override) do
    base_children =
      case Map.fetch(override, :children) do
        {:ok, override_children} -> List.wrap(override_children)
        :error -> children
      end

    base_children ++ List.wrap(Map.get(override, :append_children, []))
  end

  defp skip_node?(node, overrides) do
    Map.get(overrides, node.id, Map.get(overrides, node.component_name, %{}))
    |> Map.get(:skip?, false)
  end

  defp normalize_override(nil), do: %{}
  defp normalize_override(false), do: %{skip?: true}
  defp normalize_override(true), do: %{}
  defp normalize_override(override) when is_list(override), do: Enum.into(override, %{})
  defp normalize_override(override) when is_map(override), do: override

  defp normalize_props(props) when is_map(props), do: props
  defp normalize_props(props) when is_list(props), do: Enum.into(props, %{})
  defp normalize_props(_props), do: %{}

  defp normalize_subject_id(nil), do: nil
  defp normalize_subject_id(subject_id) when is_binary(subject_id), do: subject_id
  defp normalize_subject_id(subject_id), do: to_string(subject_id)

  defp resolve_opts(assigns) do
    []
    |> maybe_put(:view, Map.get(assigns, :view))
    |> maybe_put(:bindings, Map.get(assigns, :bindings))
    |> maybe_put(:state, Map.get(assigns, :state))
    |> maybe_put(:context, Map.get(assigns, :context))
    |> maybe_put(:domain, Map.get(assigns, :domain))
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp runtime_assigns(node, resolve_opts) do
    bindings = Keyword.get(resolve_opts, :bindings, %{})
    state = Keyword.get(resolve_opts, :state)
    binding_name = Map.get(node, :binding)
    state_key = Map.get(node, :state_key)

    %{
      node: node,
      view: Keyword.get(resolve_opts, :view),
      bindings: bindings,
      state: state,
      context: Keyword.get(resolve_opts, :context),
      binding_name: binding_name,
      bound_value: binding_name && Map.get(bindings, binding_name),
      refresh_meta: refresh_meta(state, binding_name),
      state_key: state_key,
      state_slice: state_slice(state, state_key),
      node_refresh: Map.get(node, :refresh),
      node_variant: Map.get(node, :variant)
    }
  end

  defp refresh_meta(_state, nil), do: %{}

  defp refresh_meta(state, binding_name) do
    get_in(normalize_state(state), [:refresh, binding_name]) || %{}
  end

  defp state_slice(_state, nil), do: nil

  defp state_slice(state, state_key) when is_list(state_key) do
    get_in(normalize_state(state), Enum.map(state_key, &normalize_state_key/1))
  rescue
    ArgumentError -> nil
  end

  defp state_slice(state, state_key) do
    normalized_state = normalize_state(state)
    normalized_key = normalize_state_key(state_key)

    Map.get(normalized_state, normalized_key) || Map.get(normalized_state, state_key)
  end

  defp normalize_state(nil), do: %{}
  defp normalize_state(%_{} = state), do: Map.from_struct(state)
  defp normalize_state(state) when is_map(state), do: state
  defp normalize_state(_state), do: %{}

  defp normalize_state_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp normalize_state_key(key), do: key

  defp maybe_put_prop(props, _key, nil), do: props
  defp maybe_put_prop(props, key, value), do: Map.put_new(props, key, value)

  defp normalize_data_attr(nil), do: nil

  defp normalize_data_attr(value) when is_list(value),
    do: Enum.join(Enum.map(value, &to_string/1), ".")

  defp normalize_data_attr(value), do: to_string(value)
end
