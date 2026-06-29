defmodule AshSDUI.LiveResource.Subscriptions do
  @moduledoc false

  import Phoenix.LiveView

  alias AshSDUI.Binding
  alias AshSDUI.LiveResource.Runtime
  alias AshSDUI.Runtime.State, as: RuntimeState

  def register(socket, view, opts) do
    specs = Runtime.subscription_specs(view, opts)

    if connected?(socket) do
      Enum.each(specs, &register_subscription(socket, &1))
    end

    Phoenix.Component.assign(socket, :ash_sdui_subscription_specs, specs)
  end

  def handle_info(owner, message, socket) do
    case apply_live_message(owner, socket, message) do
      {:ok, socket} -> {:noreply, socket}
      :ignore -> {:noreply, socket}
      {:error, reason} -> {:noreply, put_flash(socket, :error, inspect(reason))}
    end
  end

  def refresh_single_binding(owner, socket, binding_name) do
    view = socket.assigns.ash_sdui_view
    binding = Enum.find(view.bindings, &(&1.name == binding_name))

    if binding do
      case Runtime.load_single_binding(
             binding,
             view,
             socket.assigns.ash_sdui_opts,
             socket.assigns.ash_sdui_params,
             socket.assigns.ash_sdui_bindings
           ) do
        {:ok, value} ->
          socket
          |> Runtime.update_binding_runtime(binding, value)
          |> maybe_schedule_poll(binding)

        {:error, reason} ->
          state =
            socket.assigns.ash_sdui_state
            |> RuntimeState.mark_offline(reason)
            |> RuntimeState.record_error(binding_name, reason)

          view = %{socket.assigns.ash_sdui_view | state: state}

          socket
          |> Phoenix.Component.assign(:ash_sdui_state, state)
          |> Phoenix.Component.assign(:ash_sdui_view, view)
          |> put_flash(:error, "Could not refresh #{binding_name}.")
      end
    else
      Runtime.refresh_socket(owner, socket, %{})
    end
  end

  defp apply_live_message(owner, socket, {:ash_sdui_poll, binding}) do
    {:ok, refresh_single_binding(owner, socket, binding)}
  end

  defp apply_live_message(_owner, socket, message) do
    case matching_live_binding(socket, message) do
      nil ->
        :ignore

      binding ->
        with {:ok, current} <- {:ok, Map.get(socket.assigns.ash_sdui_bindings || %{}, binding.name)},
             {:ok, next, _meta} <- Binding.apply_update(binding, current, message) do
          {:ok, Runtime.update_binding_runtime(socket, binding, next)}
        end
    end
  end

  defp matching_live_binding(socket, message) do
    socket.assigns.ash_sdui_view.bindings
    |> Enum.find(&Binding.subscription_match?(&1, message))
  end

  defp register_subscription(_socket, %{kind: :poll, binding: binding, interval: interval})
       when is_integer(interval) and interval > 0 do
    Process.send_after(self(), {:ash_sdui_poll, binding}, interval)
  end

  defp register_subscription(socket, %{kind: :pubsub, topic: topic} = spec)
       when not is_nil(topic) do
    if pubsub_server = Map.get(spec, :pubsub_server) || endpoint_pubsub_server(socket) do
      Phoenix.PubSub.subscribe(pubsub_server, topic)
    end
  end

  defp register_subscription(_socket, _spec), do: :ok

  defp maybe_schedule_poll(socket, %AshSDUI.Binding{
         subscription: %{kind: :poll, interval: interval},
         name: name
       })
       when is_integer(interval) and interval > 0 do
    Process.send_after(self(), {:ash_sdui_poll, name}, interval)
    socket
  end

  defp maybe_schedule_poll(socket, _binding), do: socket

  defp endpoint_pubsub_server(socket) do
    endpoint = socket.endpoint

    cond do
      is_nil(endpoint) -> nil
      function_exported?(endpoint, :config, 1) -> endpoint.config(:pubsub_server)
      true -> nil
    end
  rescue
    _ -> nil
  end
end
