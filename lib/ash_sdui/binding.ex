defmodule AshSDUI.Binding do
  @moduledoc """
  Generic data binding model for views.

  Bindings describe where data comes from. The current implementation supports
  planning and basic runtime loading for Ash resources, relationships, and
  assigns, while staying small enough to compose declaratively in the SDUI DSL.
  """

  alias AshSDUI.Context
  alias AshSDUI.Query

  defstruct [
    :name,
    :source,
    :many?,
    :query,
    :default,
    :value,
    :source_meta
  ]

  @type t :: %__MODULE__{
          name: atom,
          source: term,
          many?: boolean,
          query: Query.t() | atom | nil,
          default: term,
          value: term,
          source_meta: term
        }

  @doc "Normalizes a binding source into a concrete runtime binding."
  @spec resolve(struct | map, Context.t() | map | keyword | nil) :: t
  def resolve(binding, context \\ nil) do
    context = Context.new(context)
    source = Map.get(binding, :source)
    many? = infer_many?(binding, source)

    %__MODULE__{
      name: Map.get(binding, :name),
      source: source,
      many?: many?,
      query: Map.get(binding, :query),
      default: Map.get(binding, :default),
      value: resolve_value(source, context, Map.get(binding, :default)),
      source_meta: binding
    }
  end

  @doc "Builds a loading plan for a list of bindings."
  @spec plan([struct | map], Context.t() | map | keyword | nil) :: [t]
  def plan(bindings, context \\ nil) do
    Enum.map(List.wrap(bindings), &resolve(&1, context))
  end

  @doc "Loads binding values that require an Ash read."
  @spec load([t], keyword) :: {:ok, map} | {:error, term}
  def load(bindings, opts \\ []) do
    actor = Keyword.get(opts, :actor)
    tenant = Keyword.get(opts, :tenant)
    domain = Keyword.get(opts, :domain)
    record = Keyword.get(opts, :record)
    record_id = Keyword.get(opts, :record_id)

    Enum.reduce_while(bindings, {:ok, %{}}, fn binding, {:ok, acc} ->
      case load_binding(binding,
             actor: actor,
             tenant: tenant,
             domain: domain,
             record: record,
             record_id: record_id
           ) do
        {:ok, value} -> {:cont, {:ok, Map.put(acc, binding.name, value)}}
        {:error, reason} -> {:halt, {:error, {binding.name, reason}}}
      end
    end)
  end

  defp infer_many?(binding, source) do
    case Map.get(binding, :many?) do
      value when is_boolean(value) -> value
      nil -> match?({:resource, _}, source) or match?({:relationship, _}, source)
    end
  end

  defp resolve_value({:assign, key}, %Context{assigns: assigns}, default) do
    Map.get(assigns, key, default)
  end

  defp resolve_value({:actor}, %Context{actor: actor}, default), do: actor || default
  defp resolve_value({:tenant}, %Context{tenant: tenant}, default), do: tenant || default
  defp resolve_value(_source, _context, default), do: default

  defp load_binding(%__MODULE__{source: {:assign, _}, value: value}, _opts), do: {:ok, value}
  defp load_binding(%__MODULE__{source: {:actor}, value: value}, _opts), do: {:ok, value}
  defp load_binding(%__MODULE__{source: {:tenant}, value: value}, _opts), do: {:ok, value}

  defp load_binding(
         %__MODULE__{source: {:resource, resource}, many?: many?, query: query, default: default},
         opts
       ) do
    query = normalize_query(query)
    ash_opts = [actor: opts[:actor], tenant: opts[:tenant], domain: opts[:domain]]

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
      id = (opts[:record] && Map.get(opts[:record], :id)) || opts[:record_id]

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

  defp load_binding(%__MODULE__{source: {:relationship, relationship}, default: default}, opts) do
    case opts[:record] do
      nil ->
        {:ok, default}

      record ->
        case Ash.load(record, [relationship],
               actor: opts[:actor],
               tenant: opts[:tenant],
               domain: opts[:domain]
             ) do
          {:ok, loaded} -> {:ok, Map.get(loaded, relationship, default)}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp load_binding(%__MODULE__{value: value}, _opts), do: {:ok, value}

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
