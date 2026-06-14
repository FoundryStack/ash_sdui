defmodule AshSDUI.Form do
  @moduledoc """
  Introspection helpers for building forms from SDUI metadata and Ash actions.
  """

  alias AshSDUI.Resource.Info

  @doc """
  Returns ordered field metadata for an action using visible `ui_attribute`
  definitions that are accepted by that action.
  """
  def fields(resource_or_ui, action_name) do
    resource = Info.for_resource(resource_or_ui)
    action = Ash.Resource.Info.action(resource, action_name)

    accepted =
      case action do
        nil -> []
        %{accept: accept} -> MapSet.new(accept || [])
      end

    resource_or_ui
    |> Info.ui_attributes()
    |> Enum.reject(& &1.hidden)
    |> Enum.reject(&(&1.form? == false))
    |> Enum.filter(&MapSet.member?(accepted, &1.name))
    |> Enum.sort_by(& &1.order)
    |> Enum.map(fn attr ->
      attribute = Ash.Resource.Info.attribute(resource, attr.name)

      %{
        name: attr.name,
        label: Info.resolve_label(attr, resource_or_ui),
        widget: attr.widget || infer_widget(attribute),
        field_component: attr.field_component,
        type: attribute && attribute.type,
        required: attribute && attribute.allow_nil? == false
      }
    end)
  end

  defp infer_widget(%{type: Ash.Type.Atom}), do: :text_input
  defp infer_widget(%{type: Ash.Type.String}), do: :text_input
  defp infer_widget(%{type: :string}), do: :text_input
  defp infer_widget(%{type: :utc_datetime}), do: :datetime
  defp infer_widget(_), do: :text_input
end
