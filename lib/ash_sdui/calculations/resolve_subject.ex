defmodule AshSDUI.Calculations.ResolveSubject do
  @moduledoc """
  Utility module for resolving {subject_resource, subject_id} into a live Ash record.
  """

  def resolve(record) do
    with resource_name when not is_nil(resource_name) <- record.subject_resource,
         subject_id when not is_nil(subject_id) <- record.subject_id,
         {:ok, resource_module} <- resolve_module(resource_name) do
      # Handle special ordinal subjects: "first", "second", "third", etc.
      actual_id =
        case ordinal_index(subject_id) do
          nil ->
            subject_id

          index ->
            case Ash.read(resource_module) do
              {:ok, records} when length(records) > index -> Enum.at(records, index).id
              _ -> nil
            end
        end

      if actual_id do
        case Ash.get(resource_module, actual_id) do
          {:ok, result} -> result
          _ -> nil
        end
      else
        nil
      end
    else
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp resolve_module(resource_name) do
    module = Module.concat([resource_name])

    case Code.ensure_loaded(module) do
      {:module, mod} -> {:ok, mod}
      {:error, _} -> {:error, :not_loaded}
    end
  end

  @ordinals %{
    "first" => 0,
    "second" => 1,
    "third" => 2,
    "fourth" => 3,
    "fifth" => 4
  }

  defp ordinal_index(subject_id), do: Map.get(@ordinals, subject_id)
end
