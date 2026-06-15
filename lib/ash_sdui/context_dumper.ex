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
      views = Info.views(resource)
      intents = Info.ui_intents(resource)
      fields = Info.ui_fields(resource)

      """
      ### #{inspect(resource)}

      - **Default Component**: #{default_component || "none"}
      - **Views**: #{view_list(views)}
      - **UI Intents**: #{intent_list(intents)}
      - **UI Fields**: #{field_list(fields)}
      """
    end)
    |> Enum.join("\n")
  end

  defp resource_json(resource) do
    %{
      module: to_string(resource),
      default_component: Info.default_component(resource),
      views: Info.views(resource) |> Enum.map(&view_json/1),
      ui_intents: Info.ui_intents(resource) |> Enum.map(&intent_json/1),
      ui_fields: Info.ui_fields(resource) |> Enum.map(&field_json/1)
    }
  end

  defp view_list(views) do
    case views do
      [] -> "none"
      views -> Enum.map(views, &":#{&1.name}") |> Enum.join(", ")
    end
  end

  defp view_json(view) do
    %{
      name: view.name,
      recipe: view.recipe,
      action: view.action,
      read_action: view.read_action,
      query: view.query
    }
  end

  defp intent_list(intents) do
    case intents do
      [] -> "none"
      intents -> Enum.map(intents, &":#{&1.name}") |> Enum.join(", ")
    end
  end

  defp intent_json(intent) do
    %{
      name: intent.name,
      style: intent.style,
      label: intent.label,
      icon: intent.icon,
      target: inspect(intent.target)
    }
  end

  defp field_list(fields) do
    case fields do
      [] -> "none"
      fields -> Enum.map(fields, &":#{&1.name}") |> Enum.join(", ")
    end
  end

  defp field_json(field) do
    %{
      name: field.name,
      label: field.label,
      icon: field.icon,
      hidden: field.hidden,
      order: field.order,
      widget: field.widget,
      binding: field.binding,
      field_component: field.field_component && to_string(field.field_component)
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
