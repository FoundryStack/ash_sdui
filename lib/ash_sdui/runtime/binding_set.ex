defmodule AshSDUI.Runtime.BindingSet do
  @moduledoc """
  Shared helpers for looking up primary and selected binding values.
  """

  alias AshSDUI.Binding
  alias AshSDUI.Runtime.State
  alias AshSDUI.View

  @spec primary_collection(View.t() | [Binding.t()] | nil, map | nil) :: term
  def primary_collection(view_or_bindings, bindings) do
    with %Binding{name: name} <- primary_collection_binding(view_or_bindings) do
      Map.get(bindings || %{}, name)
    end
  end

  @spec primary_record(View.t() | [Binding.t()] | nil, map | nil) :: term
  def primary_record(view_or_bindings, bindings) do
    with %Binding{name: name} <- primary_record_binding(view_or_bindings) do
      Map.get(bindings || %{}, name)
    end
  end

  @spec primary_collection_name(View.t() | [Binding.t()] | nil) :: atom | nil
  def primary_collection_name(view_or_bindings) do
    case primary_collection_binding(view_or_bindings) do
      %Binding{name: name} -> name
      _ -> nil
    end
  end

  @spec primary_record_name(View.t() | [Binding.t()] | nil) :: atom | nil
  def primary_record_name(view_or_bindings) do
    case primary_record_binding(view_or_bindings) do
      %Binding{name: name} -> name
      _ -> nil
    end
  end

  @spec selected_records(View.State.t() | map | nil, map | nil, View.t() | [Binding.t()] | nil) ::
          list
  def selected_records(state, bindings, view_or_bindings) do
    view_or_bindings
    |> primary_collection(bindings)
    |> then(&State.selected_records(state, &1))
  end

  defp primary_collection_binding(%View{bindings: bindings}), do: primary_collection_binding(bindings)
  defp primary_collection_binding(bindings) when is_list(bindings), do: Enum.find(bindings, & &1.many?)
  defp primary_collection_binding(_bindings), do: nil

  defp primary_record_binding(%View{bindings: bindings}), do: primary_record_binding(bindings)
  defp primary_record_binding(bindings) when is_list(bindings), do: Enum.find(bindings, &(not &1.many?))
  defp primary_record_binding(_bindings), do: nil
end
