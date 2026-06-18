defmodule AshSDUI.LiveResource.IntentDispatch do
  @moduledoc false

  import Phoenix.LiveView

  alias AshSDUI.Intent
  alias AshSDUI.LiveResource.Runtime
  alias AshSDUI.View

  def dispatch(owner, %{"intent" => intent_name} = params, socket) do
    with {:ok, intent} <- lookup_intent(socket.assigns.ash_sdui_view, intent_name),
         {:ok, command} <- Intent.command(intent, params, intent_runtime(socket, params)) do
      apply_command(owner, socket, command)
    else
      {:error, _reason} ->
        put_flash(socket, :error, "Intent could not be executed.")
    end
  end

  def dispatch(_owner, _params, socket), do: socket

  defp apply_command(_owner, socket, %{type: :navigate, meta: %{to: to}}) do
    push_navigate(socket, to: to)
  end

  defp apply_command(_owner, socket, %{type: :patch, meta: %{to: to}}) do
    push_patch(socket, to: to)
  end

  defp apply_command(owner, socket, %{type: :refresh, meta: meta}) do
    Runtime.refresh_socket(owner, socket, refresh_params(meta))
  end

  defp apply_command(_owner, socket, %{type: :select, meta: %{operation: operation}, payload: payload}) do
    selection_params =
      payload
      |> Map.take(["id", :id])
      |> Map.put_new("operation", normalize_selection_operation(operation))

    Runtime.update_selection(socket, selection_params)
  end

  defp apply_command(_owner, socket, %{type: :workflow, meta: %{event: event}}) do
    Runtime.update_workflow(socket, %{"event" => to_string(event)})
  end

  defp apply_command(_owner, socket, %{type: :event, meta: %{event: event}, payload: payload}) do
    socket
    |> put_flash(:info, "Triggered #{event}.")
    |> update_runtime_state(fn state ->
      %{state | assigns: Map.put(state.assigns || %{}, :last_event, payload)}
    end)
  end

  defp apply_command(_owner, socket, %{type: :ash_action}) do
    put_flash(socket, :info, "Use the generated form flow to run this action.")
  end

  defp apply_command(_owner, socket, _command), do: socket

  defp lookup_intent(%View{intents: intents}, intent_name) do
    intent_atom =
      cond do
        is_atom(intent_name) -> intent_name
        is_binary(intent_name) -> String.to_existing_atom(intent_name)
        true -> intent_name
      end

    case Enum.find(intents, &(&1.name == intent_atom)) do
      nil -> {:error, :intent_not_found}
      intent -> {:ok, intent}
    end
  rescue
    ArgumentError -> {:error, :invalid_intent}
  end

  defp intent_runtime(socket, params) do
    %{
      actor: socket.assigns.ash_sdui_context.actor,
      tenant: socket.assigns.ash_sdui_context.tenant,
      domain: Runtime.root_domain(socket.assigns.ash_sdui_resource, socket.assigns.ash_sdui_opts),
      resource: socket.assigns.ash_sdui_resource,
      record: socket.assigns[:subject],
      params: params
    }
  end

  defp refresh_params(%{binding: nil}), do: %{}
  defp refresh_params(%{binding: :view}), do: %{}
  defp refresh_params(%{binding: binding}) when is_atom(binding), do: %{"binding" => Atom.to_string(binding)}
  defp refresh_params(_meta), do: %{}

  defp normalize_selection_operation({mode, _opts}) when is_atom(mode), do: Atom.to_string(mode)
  defp normalize_selection_operation(mode) when is_atom(mode), do: Atom.to_string(mode)
  defp normalize_selection_operation(mode) when is_binary(mode), do: mode
  defp normalize_selection_operation(_mode), do: "toggle"

  defp update_runtime_state(socket, fun) do
    state = AshSDUI.Runtime.State.update(socket.assigns.ash_sdui_state, fun)
    view = %{socket.assigns.ash_sdui_view | state: state}

    socket
    |> Phoenix.Component.assign(:ash_sdui_state, state)
    |> Phoenix.Component.assign(:ash_sdui_view, view)
  end
end
