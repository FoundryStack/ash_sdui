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
    :source_meta,
    refresh: :manual,
    update: :replace,
    update_strategy: :replace,
    source_kind: :static,
    status: :ready,
    subscription: nil
  ]

  @type t :: %__MODULE__{
          name: atom,
          source: term,
          many?: boolean,
          query: Query.t() | atom | nil,
          default: term,
          value: term,
          source_meta: term,
          refresh: term,
          update: term,
          update_strategy: atom | term,
          source_kind: atom,
          status: atom,
          subscription: map | nil
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
      source_meta: binding,
      refresh: normalize_refresh(Map.get(binding, :refresh, infer_refresh(source))),
      update: normalize_update_strategy(Map.get(binding, :update, :replace)),
      update_strategy: normalize_update_strategy(Map.get(binding, :update, :replace)),
      source_kind: infer_source_kind(source),
      status: infer_status(source),
      subscription: build_subscription(source)
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

  @doc "Returns normalized subscription specs for bindings that can update live."
  @spec subscription_specs([t], keyword) :: [map]
  def subscription_specs(bindings, opts \\ []) do
    pubsub_server = Keyword.get(opts, :pubsub_server)

    bindings
    |> List.wrap()
    |> Enum.reduce([], fn binding, acc ->
      case binding.subscription do
        nil ->
          acc

        subscription ->
          [
            subscription
            |> Map.put(:binding, binding.name)
            |> Map.put(:source_kind, binding.source_kind)
            |> Map.put(:update_strategy, binding.update_strategy)
            |> maybe_put_spec(:pubsub_server, pubsub_server)
            | acc
          ]
      end
    end)
    |> Enum.reverse()
  end

  @doc "Normalizes an incoming live update and applies it to the current binding value."
  @spec apply_update(t, term, term) :: {:ok, term, map} | {:error, term}
  def apply_update(%__MODULE__{} = binding, current, message) do
    with {:ok, update} <- normalize_live_update(binding, message),
         {:ok, next} <- run_update_strategy(binding, current, update) do
      {:ok, next, update}
    end
  end

  @doc "Returns true when a message matches a binding subscription spec."
  @spec subscription_match?(t, term) :: boolean
  def subscription_match?(%__MODULE__{subscription: nil}, _message), do: false

  def subscription_match?(
        %__MODULE__{name: name, subscription: %{kind: :poll}},
        {:ash_sdui_poll, name}
      ),
      do: true

  def subscription_match?(%__MODULE__{subscription: subscription}, message) do
    event = Map.get(subscription, :event)

    cond do
      is_nil(event) ->
        true

      match?(%{event: ^event}, message) ->
        true

      match?({^event, _}, message) ->
        true

      match?({:ash_sdui_event, ^event, _}, message) ->
        true

      true ->
        false
    end
  end

  defp infer_many?(binding, source) do
    case Map.get(binding, :many?) do
      value when is_boolean(value) -> value
      nil -> infer_many_from_source(source)
    end
  end

  defp infer_many_from_source({:resource, _}), do: true
  defp infer_many_from_source({:relationship, _}), do: true
  defp infer_many_from_source({:poll, source, _opts}), do: infer_many_from_source(source)
  defp infer_many_from_source({:stream, source, _opts}), do: infer_many_from_source(source)

  defp infer_many_from_source({:pubsub, _topic, opts}),
    do: infer_many_from_source(pubsub_source(opts))

  defp infer_many_from_source(_source), do: false

  defp infer_refresh({:poll, _source, opts}), do: Keyword.get(opts, :interval, :interval)
  defp infer_refresh({:pubsub, _topic, _opts}), do: :subscription
  defp infer_refresh({:stream, _source, _opts}), do: :subscription
  defp infer_refresh(_source), do: :manual

  defp infer_source_kind({:resource, _}), do: :resource
  defp infer_source_kind({:relationship, _}), do: :relationship
  defp infer_source_kind({:assign, _}), do: :assign
  defp infer_source_kind({:context, _}), do: :context
  defp infer_source_kind({:runtime, _}), do: :runtime
  defp infer_source_kind({:event, _}), do: :event
  defp infer_source_kind({:selection}), do: :selection
  defp infer_source_kind({:subject}), do: :subject
  defp infer_source_kind({:actor}), do: :context
  defp infer_source_kind({:tenant}), do: :context
  defp infer_source_kind({:poll, _, _}), do: :poll
  defp infer_source_kind({:pubsub, _, _}), do: :pubsub
  defp infer_source_kind({:stream, _, _}), do: :stream
  defp infer_source_kind(_), do: :static

  defp infer_status({:poll, _, _}), do: :scheduled
  defp infer_status({:pubsub, _, _}), do: :subscribed
  defp infer_status({:stream, _, _}), do: :streaming
  defp infer_status(_source), do: :ready

  defp build_subscription({:poll, _source, opts}) do
    %{kind: :poll, interval: Keyword.fetch!(opts, :interval)}
  end

  defp build_subscription({:pubsub, topic, opts}) do
    %{
      kind: :pubsub,
      topic: topic,
      event: Keyword.get(opts, :event),
      reducer: Keyword.get(opts, :reducer),
      key: Keyword.get(opts, :key, :id)
    }
  end

  defp build_subscription({:stream, _source, opts}) do
    %{
      kind: :stream,
      event: Keyword.get(opts, :event),
      reducer: Keyword.get(opts, :reducer),
      key: Keyword.get(opts, :key, :id)
    }
  end

  defp build_subscription(_source), do: nil

  defp normalize_refresh({:interval, ms}) when is_integer(ms) and ms > 0, do: {:interval, ms}
  defp normalize_refresh(ms) when is_integer(ms) and ms > 0, do: {:interval, ms}
  defp normalize_refresh(other), do: other

  defp normalize_update_strategy(strategy)
       when strategy in [:replace, :append, :prepend, :merge, :remove],
       do: strategy

  defp normalize_update_strategy(other), do: other

  defp resolve_value({:assign, key}, %Context{assigns: assigns}, default) do
    Map.get(assigns, key, default)
  end

  defp resolve_value({:context, key}, %Context{} = context, default) do
    Map.get(Map.from_struct(context), key, default)
  end

  defp resolve_value({:runtime, key}, %Context{assigns: assigns}, default) do
    Map.get(assigns[:runtime] || %{}, key, default)
  end

  defp resolve_value({:poll, source, _opts}, context, default) do
    resolve_value(source, context, default)
  end

  defp resolve_value({:stream, source, _opts}, context, default) do
    resolve_value(source, context, default)
  end

  defp resolve_value({:pubsub, _topic, opts}, context, default) do
    case pubsub_source(opts) do
      nil -> default
      source -> resolve_value(source, context, default)
    end
  end

  defp resolve_value({:selection}, %Context{assigns: assigns}, default) do
    Map.get(assigns, :selection, default)
  end

  defp resolve_value({:subject}, %Context{assigns: assigns}, default) do
    Map.get(assigns, :subject, default)
  end

  defp resolve_value({:actor}, %Context{actor: actor}, default), do: actor || default
  defp resolve_value({:tenant}, %Context{tenant: tenant}, default), do: tenant || default
  defp resolve_value(_source, _context, default), do: default

  defp load_binding(%__MODULE__{source: {:assign, _}, value: value}, _opts), do: {:ok, value}
  defp load_binding(%__MODULE__{source: {:context, _}, value: value}, _opts), do: {:ok, value}
  defp load_binding(%__MODULE__{source: {:runtime, _}, value: value}, _opts), do: {:ok, value}
  defp load_binding(%__MODULE__{source: {:selection}, value: value}, _opts), do: {:ok, value}
  defp load_binding(%__MODULE__{source: {:subject}, value: value}, _opts), do: {:ok, value}
  defp load_binding(%__MODULE__{source: {:actor}, value: value}, _opts), do: {:ok, value}
  defp load_binding(%__MODULE__{source: {:tenant}, value: value}, _opts), do: {:ok, value}

  defp load_binding(%__MODULE__{source: {:poll, source, _opts}} = binding, opts) do
    load_binding(%{binding | source: source}, opts)
  end

  defp load_binding(%__MODULE__{source: {:stream, source, _opts}} = binding, opts) do
    load_binding(%{binding | source: source}, opts)
  end

  defp load_binding(%__MODULE__{source: {:pubsub, _topic, opts}} = binding, load_opts) do
    case pubsub_source(opts) do
      nil -> {:ok, binding.default}
      source -> load_binding(%{binding | source: source}, load_opts)
    end
  end

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

  defp normalize_live_update(binding, message) do
    reducer = get_in(binding.subscription || %{}, [:reducer])

    case run_reducer(reducer, message, binding) do
      {:ok, update} -> normalize_update_payload(update, binding)
      {:error, _reason} = error -> error
      update -> normalize_update_payload(update, binding)
    end
  end

  defp run_reducer(nil, message, _binding), do: message

  defp run_reducer(function, message, binding) when is_function(function, 2),
    do: function.(message, binding)

  defp run_reducer({module, function}, message, binding)
       when is_atom(module) and is_atom(function),
       do: apply(module, function, [message, binding])

  defp run_reducer(function, message, binding) when is_atom(function) do
    apply(__MODULE__.Reducers, function, [message, binding])
  rescue
    UndefinedFunctionError -> {:error, {:unknown_reducer, function}}
  end

  defp normalize_update_payload({:ok, update}, binding),
    do: normalize_update_payload(update, binding)

  defp normalize_update_payload({:error, _reason} = error, _binding), do: error

  defp normalize_update_payload(%{operation: operation} = update, binding) do
    {:ok,
     update
     |> Map.put(:operation, normalize_update_strategy(operation))
     |> Map.put_new(:key, binding_key(binding))}
  end

  defp normalize_update_payload({operation, payload}, binding)
       when operation in [:append, :prepend, :merge] do
    {:ok, %{operation: operation, item: payload, key: binding_key(binding)}}
  end

  defp normalize_update_payload({:remove, payload}, binding) do
    {:ok, %{operation: :remove, item: payload, key: binding_key(binding)}}
  end

  defp normalize_update_payload({:replace, payload}, binding) do
    {:ok, %{operation: :replace, items: List.wrap(payload), key: binding_key(binding)}}
  end

  defp normalize_update_payload(%{event: _event, payload: payload}, binding),
    do: normalize_update_payload(payload, binding)

  defp normalize_update_payload({:ash_sdui_event, _event, payload}, binding),
    do: normalize_update_payload(payload, binding)

  defp normalize_update_payload(other, binding) when is_list(other) do
    {:ok, %{operation: binding.update_strategy, items: other, key: binding_key(binding)}}
  end

  defp normalize_update_payload(other, binding) when is_map(other) do
    operation = binding.update_strategy
    key = binding_key(binding)

    {:ok,
     case operation do
       :replace -> %{operation: :replace, items: List.wrap(other), key: key}
       :remove -> %{operation: :remove, item: other, key: key}
       _ -> %{operation: operation, item: other, key: key}
     end}
  end

  defp normalize_update_payload(other, _binding),
    do: {:error, {:unsupported_update_payload, other}}

  defp run_update_strategy(binding, current, %{operation: operation} = update) do
    key = Map.get(update, :key, binding_key(binding))
    current = normalize_collection(current)

    case operation do
      :replace ->
        {:ok, normalize_replace(update)}

      :append ->
        {:ok, current ++ normalize_items(update)}

      :prepend ->
        {:ok, normalize_items(update) ++ current}

      :merge ->
        {:ok, merge_items(current, normalize_items(update), key)}

      :remove ->
        {:ok, remove_items(current, update, key)}

      other ->
        {:error, {:unsupported_update_strategy, other}}
    end
  end

  defp normalize_replace(update) do
    update
    |> normalize_items()
  end

  defp normalize_items(%{items: items}) when is_list(items), do: items
  defp normalize_items(%{item: item}), do: [item]
  defp normalize_items(items) when is_list(items), do: items
  defp normalize_items(item), do: [item]

  defp normalize_collection(nil), do: []
  defp normalize_collection(items) when is_list(items), do: items
  defp normalize_collection(item), do: [item]

  defp merge_items(current, incoming, key) do
    Enum.reduce(incoming, current, fn item, acc ->
      item_key = item_lookup(item, key)

      case Enum.find_index(acc, &(item_lookup(&1, key) == item_key)) do
        nil -> acc ++ [item]
        index -> List.replace_at(acc, index, merge_record(Enum.at(acc, index), item))
      end
    end)
  end

  defp remove_items(current, %{id: id}, key) do
    Enum.reject(current, &(item_lookup(&1, key) == id))
  end

  defp remove_items(current, %{item: item}, key) when is_map(item) do
    id = item_lookup(item, key)
    Enum.reject(current, &(item_lookup(&1, key) == id))
  end

  defp remove_items(current, %{item: id}, key) do
    Enum.reject(current, &(item_lookup(&1, key) == id))
  end

  defp merge_record(left, right) when is_map(left) and is_map(right), do: Map.merge(left, right)
  defp merge_record(_left, right), do: right

  defp item_lookup(item, key) when is_map(item),
    do: Map.get(item, key) || Map.get(item, to_string(key))

  defp item_lookup(item, _key), do: item

  defp binding_key(%__MODULE__{subscription: subscription}) do
    Map.get(subscription || %{}, :key, :id)
  end

  defp pubsub_source(opts), do: Keyword.get(opts, :source)
  defp maybe_put_spec(spec, _key, nil), do: spec
  defp maybe_put_spec(spec, key, value), do: Map.put(spec, key, value)

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

  defmodule Reducers do
    @moduledoc false

    def passthrough(message, _binding), do: message

    def stream_event(%{payload: payload}, _binding), do: payload
    def stream_event({:ash_sdui_event, _event, payload}, _binding), do: payload
    def stream_event({_event, payload}, _binding), do: payload
    def stream_event(payload, _binding), do: payload
  end
end
