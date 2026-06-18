defmodule AshSDUI.Binding.Subscription do
  @moduledoc false

  alias AshSDUI.Binding

  @spec subscription_specs([Binding.t()], keyword) :: [map]
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

  @spec subscription_match?(Binding.t(), term) :: boolean
  def subscription_match?(%Binding{subscription: nil}, _message), do: false

  def subscription_match?(%Binding{name: name, subscription: %{kind: :poll}}, {:ash_sdui_poll, name}),
    do: true

  def subscription_match?(%Binding{subscription: subscription}, message) do
    event = Map.get(subscription, :event)

    cond do
      is_nil(event) -> true
      Kernel.match?(%{event: ^event}, message) -> true
      Kernel.match?({^event, _}, message) -> true
      Kernel.match?({:ash_sdui_event, ^event, _}, message) -> true
      true -> false
    end
  end

  defp maybe_put_spec(spec, _key, nil), do: spec
  defp maybe_put_spec(spec, key, value), do: Map.put(spec, key, value)
end
