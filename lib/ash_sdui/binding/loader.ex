defmodule AshSDUI.Binding.Loader do
  @moduledoc false

  alias AshSDUI.Binding
  alias AshSDUI.Binding.Source
  alias AshSDUI.Query

  @type load_context :: %{
          actor: term,
          tenant: term,
          domain: term,
          record: term,
          record_id: term
        }

  @spec new_context(keyword | map) :: load_context
  def new_context(opts) when is_list(opts) do
    new_context(Enum.into(opts, %{}))
  end

  def new_context(opts) when is_map(opts) do
    %{
      actor: Map.get(opts, :actor),
      tenant: Map.get(opts, :tenant),
      domain: Map.get(opts, :domain),
      record: Map.get(opts, :record),
      record_id: Map.get(opts, :record_id)
    }
  end

  @spec load([Binding.t()], keyword | map) :: {:ok, map} | {:error, term}
  def load(bindings, opts \\ []) do
    context = new_context(opts)

    Enum.reduce_while(bindings, {:ok, %{}}, fn binding, {:ok, acc} ->
      case load_binding(binding, context) do
        {:ok, value} -> {:cont, {:ok, Map.put(acc, binding.name, value)}}
        {:error, reason} -> {:halt, {:error, {binding.name, reason}}}
      end
    end)
  end

  @spec load_binding(Binding.t(), load_context) :: {:ok, term} | {:error, term}
  def load_binding(%Binding{source: source, value: value} = binding, context) do
    source
    |> Source.canonical_source()
    |> do_load_binding(%{binding | source: source, value: value}, context)
  end

  defp do_load_binding({:assign, _}, %Binding{value: value}, _context), do: {:ok, value}
  defp do_load_binding({:context, _}, %Binding{value: value}, _context), do: {:ok, value}
  defp do_load_binding({:runtime, _}, %Binding{value: value}, _context), do: {:ok, value}
  defp do_load_binding({:selection}, %Binding{value: value}, _context), do: {:ok, value}
  defp do_load_binding({:subject}, %Binding{value: value}, _context), do: {:ok, value}
  defp do_load_binding({:actor}, %Binding{value: value}, _context), do: {:ok, value}
  defp do_load_binding({:tenant}, %Binding{value: value}, _context), do: {:ok, value}

  defp do_load_binding(
         {:resource, resource},
         %Binding{many?: many?, query: query, default: default},
         context
       ) do
    query = normalize_query(query)
    ash_opts = [actor: context.actor, tenant: context.tenant, domain: context.domain]

    if many? do
      resource_query =
        resource
        |> Ash.Query.new()
        |> apply_query(query)

      case Ash.read(resource_query, ash_opts) do
        {:ok, records} -> {:ok, unwrap_many(records)}
        {:error, reason} -> {:error, reason}
      end
    else
      id = (context.record && Map.get(context.record, :id)) || context.record_id

      cond do
        id ->
          case Ash.get(resource, id, ash_opts) do
            {:ok, result} -> {:ok, result}
            {:error, reason} -> {:error, reason}
          end

        default != nil ->
          {:ok, default}

        true ->
          {:error, :missing_record_id}
      end
    end
  end

  defp do_load_binding(
         {:relationship, _relationship},
         %Binding{default: default},
         %{record: nil}
       ),
       do: {:ok, default}

  defp do_load_binding(
         {:relationship, relationship},
         %Binding{default: default},
         %{record: record} = context
       ) do
    case Ash.load(record, [relationship],
           actor: context.actor,
           tenant: context.tenant,
           domain: context.domain
         ) do
      {:ok, loaded} -> {:ok, Map.get(loaded, relationship, default)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_load_binding(_source, %Binding{value: value}, _context), do: {:ok, value}

  defp normalize_query(%Query{} = query), do: query
  defp normalize_query(_query), do: nil

  defp apply_query(query, nil), do: query

  defp apply_query(query, %Query{} = state) do
    query
    |> maybe_filter(state)
    |> maybe_sort(state)
    |> maybe_page(state)
  end

  defp maybe_filter(query, state) do
    case Query.to_ash_opts(state, [])[:filter] do
      nil -> query
      filter -> Ash.Query.do_filter(query, filter)
    end
  end

  defp maybe_sort(query, state) do
    case Query.to_ash_opts(state, [])[:sort] do
      nil -> query
      sort -> Ash.Query.sort(query, sort)
    end
  end

  defp maybe_page(query, state) do
    case Query.to_ash_opts(state, [])[:page] do
      nil -> query
      page -> Ash.Query.page(query, page)
    end
  end

  defp unwrap_many(%{results: results}) when is_list(results), do: results
  defp unwrap_many(records), do: records
end
