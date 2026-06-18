defmodule AshSDUI.Binding.Update do
  @moduledoc false

  alias AshSDUI.Binding

  @spec apply_update(Binding.t(), term, term) :: {:ok, term, map} | {:error, term}
  def apply_update(%Binding{} = binding, current, message) do
    with {:ok, update} <- normalize_live_update(binding, message),
         {:ok, next} <- run_update_strategy(binding, current, update) do
      {:ok, next, update}
    end
  end

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
     |> Map.put(:operation, Binding.normalize_update_strategy(operation))
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
      :replace -> {:ok, normalize_items(update)}
      :append -> {:ok, current ++ normalize_items(update)}
      :prepend -> {:ok, normalize_items(update) ++ current}
      :merge -> {:ok, merge_items(current, normalize_items(update), key)}
      :remove -> {:ok, remove_items(current, update, key)}
      other -> {:error, {:unsupported_update_strategy, other}}
    end
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

  defp binding_key(%Binding{subscription: subscription}) do
    Map.get(subscription || %{}, :key, :id)
  end

  defmodule Reducers do
    @moduledoc false

    def passthrough(message, _binding), do: message

    def stream_event(%{payload: payload}, _binding), do: payload
    def stream_event({:ash_sdui_event, _event, payload}, _binding), do: payload
    def stream_event({_event, payload}, _binding), do: payload
    def stream_event(payload, _binding), do: payload
  end
end
