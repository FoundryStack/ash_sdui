defmodule AshSDUI.ContextDumper do
  @moduledoc """
  Generates a markdown or JSON snapshot of registered SDUI components, layouts, and annotated resources.

  ## Usage

      {:ok, markdown} = AshSDUI.ContextDumper.dump(:markdown)
      IO.puts(markdown)

      {:ok, json} = AshSDUI.ContextDumper.dump(:json)
  """

  alias AshSDUI.Registry
  alias AshSDUI.Layout
  alias AshSDUI.Resource.Info

  @doc "Dump SDUI context as markdown or JSON."
  def dump(format \\ :markdown) when format in [:markdown, :json] do
    case format do
      :markdown -> {:ok, dump_markdown()}
      :json -> {:ok, dump_json()}
    end
  end

  defp dump_markdown do
    components = Registry.all()
    layouts = Layout.all()
    resources = discover_annotated_resources()

    """
    # AshSDUI Context Report

    Generated at: #{DateTime.utc_now() |> DateTime.to_iso8601()}

    ## Components (#{length(components)})

    #{component_markdown(components)}

    ## Layouts (#{length(layouts)})

    #{layout_markdown(layouts)}

    ## Annotated Resources (#{length(resources)})

    #{resource_markdown(resources)}
    """
  end

  defp dump_json do
    components = Registry.all()
    layouts = Layout.all()
    resources = discover_annotated_resources()

    %{
      generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      components: Enum.map(components, &component_json/1),
      layouts: Enum.map(layouts, &layout_json/1),
      resources: Enum.map(resources, &resource_json/1)
    }
    |> Jason.encode!(pretty: true)
  end

  defp component_markdown(components) do
    Enum.map(components, fn {name, entry} ->
      """
      ### #{name}

      - **Module**: `#{entry.module}`
      - **Subject Types**: #{Enum.join(entry.subject_types || [], ", ")}
      """
    end)
    |> Enum.join("\n")
  end

  defp component_json(%{name: name, module: module, subject_types: types}) do
    %{
      name: name,
      module: to_string(module),
      subject_types: types || []
    }
  end

  defp layout_markdown(layouts) do
    Enum.map(layouts, fn {name, _tree} ->
      "- `#{name}`"
    end)
    |> Enum.join("\n")
  end

  defp layout_json({name, _tree}) do
    %{name: name}
  end

  defp resource_markdown(resources) do
    Enum.map(resources, fn resource ->
      default_component = Info.default_component(resource)
      actions = Info.ui_actions(resource)
      attributes = Info.ui_attributes(resource)

      """
      ### #{inspect(resource)}

      - **Default Component**: #{default_component || "none"}
      - **UI Actions**: #{action_list(actions)}
      - **UI Attributes**: #{attribute_list(attributes)}
      """
    end)
    |> Enum.join("\n")
  end

  defp resource_json(resource) do
    %{
      module: to_string(resource),
      default_component: Info.default_component(resource),
      ui_actions: Info.ui_actions(resource) |> Enum.map(&action_json/1),
      ui_attributes: Info.ui_attributes(resource) |> Enum.map(&attribute_json/1)
    }
  end

  defp action_list(actions) do
    case actions do
      [] -> "none"
      actions -> Enum.map(actions, &":#{&1.name}") |> Enum.join(", ")
    end
  end

  defp action_json(action) do
    %{
      name: action.name,
      intent: action.intent,
      label: action.label,
      icon: action.icon
    }
  end

  defp attribute_list(attributes) do
    case attributes do
      [] -> "none"
      attrs -> Enum.map(attrs, &":#{&1.name}") |> Enum.join(", ")
    end
  end

  defp attribute_json(attribute) do
    %{
      name: attribute.name,
      label: attribute.label,
      icon: attribute.icon,
      hidden: attribute.hidden,
      order: attribute.order,
      widget: attribute.widget,
      field_component: attribute.field_component && to_string(attribute.field_component)
    }
  end

  defp discover_annotated_resources do
    :code.all_loaded()
    |> Enum.map(&elem(&1, 0))
    |> Enum.filter(&has_ash_sdui_resource?/1)
  end

  defp has_ash_sdui_resource?(module) do
    try do
      Code.ensure_loaded?(module) and function_exported?(module, :__ash_sdui_auto_register__, 0)
    catch
      _, _ -> false
    end
  end
end
