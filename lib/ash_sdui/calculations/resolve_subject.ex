defmodule AshSDUI.Calculations.ResolveSubject do
  @moduledoc """
  Utility module for resolving {subject_resource, subject_id} into a live Ash record.
  """

  alias AshSDUI.Context

  def resolve(record, opts \\ []) do
    context = Context.new(Keyword.get(opts, :context))

    with resource_name when not is_nil(resource_name) <- record.subject_resource,
         subject_id when not is_nil(subject_id) <- record.subject_id,
         {:ok, resource_module} <- resolve_module(resource_name) do
      ash_opts = ash_opts(resource_module, context, opts)

      # Handle special ordinal subjects: "first", "second", "third", etc.
      actual_id =
        case ordinal_index(subject_id) do
          nil ->
            subject_id

          index ->
            case Ash.read(resource_module, ash_opts) do
              {:ok, records} when length(records) > index -> Enum.at(records, index).id
              _ -> nil
            end
        end

      if actual_id do
        case Ash.get(resource_module, actual_id, ash_opts) do
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

  defp ash_opts(resource_module, context, opts) do
    []
    |> maybe_put(:domain, Keyword.get(opts, :domain) || resource_domain(resource_module))
    |> maybe_put(:actor, context.actor)
    |> maybe_put(:tenant, context.tenant)
  end

  defp resource_domain(resource_module) do
    Ash.Resource.Info.domain(resource_module)
  rescue
    _ -> nil
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
