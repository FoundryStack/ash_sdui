defmodule AshSDUI.Runtime.State do
  @moduledoc """
  Shared runtime state helpers for SDUI views and components.
  """

  alias AshSDUI.View

  @spec normalize(View.State.t() | map | nil | struct) :: map
  def normalize(nil), do: %{}
  def normalize(%View.State{} = state), do: Map.from_struct(state)
  def normalize(%_{} = state), do: Map.from_struct(state)
  def normalize(state) when is_map(state), do: state
  def normalize(_state), do: %{}

  @spec refresh_meta(View.State.t() | map | nil, atom | nil) :: map
  def refresh_meta(_state, nil), do: %{}

  def refresh_meta(state, binding_name) do
    get_in(normalize(state), [:refresh, binding_name]) || %{}
  end

  @spec state_slice(View.State.t() | map | nil, atom | String.t() | [atom | String.t()] | nil) ::
          term
  def state_slice(_state, nil), do: nil

  def state_slice(state, state_key) when is_list(state_key) do
    get_in(normalize(state), Enum.map(state_key, &normalize_key/1))
  rescue
    ArgumentError -> nil
  end

  def state_slice(state, state_key) do
    normalized_state = normalize(state)
    normalized_key = normalize_key(state_key)

    Map.get(normalized_state, normalized_key) || Map.get(normalized_state, state_key)
  end

  @spec update(View.State.t() | nil, (View.State.t() -> View.State.t())) :: View.State.t()
  def update(nil, fun) when is_function(fun, 1), do: fun.(%View.State{})
  def update(%View.State{} = state, fun) when is_function(fun, 1), do: fun.(state)

  @spec apply_selection(View.State.t() | nil, map) :: View.State.t()
  def apply_selection(state, params) do
    update(state, fn state -> %{state | selected: next_selection(state.selected, params)} end)
  end

  @spec apply_workflow(View.State.t() | nil, map) :: View.State.t()
  def apply_workflow(state, params) do
    update(state, fn state ->
      next_workflow =
        (state.workflow || %{})
        |> Map.merge(%{
          state: Map.get(params, "state", Map.get(params, :state)) || workflow_transition(params),
          last_event: Map.get(params, "event", Map.get(params, :event)),
          updated_at: DateTime.utc_now()
        })

      %{state | workflow: next_workflow}
    end)
  end

  @spec refresh_snapshot(map, View.State.t() | nil) :: map
  def refresh_snapshot(bindings, %View.State{} = state) do
    current = state.refresh || %{}
    now = DateTime.utc_now()

    bindings
    |> Enum.reduce(current, fn {name, _value}, acc ->
      Map.put_new(acc, name, %{status: :ready, refreshed_at: now})
    end)
    |> Map.put_new(:last_refreshed_at, now)
  end

  def refresh_snapshot(bindings, nil), do: refresh_snapshot(bindings, %View.State{})

  @spec mark_binding_refreshed(View.State.t() | nil, atom) :: View.State.t()
  def mark_binding_refreshed(state, binding_name) do
    update(state, fn state ->
      now = DateTime.utc_now()

      refresh =
        (state.refresh || %{})
        |> Map.put(binding_name, %{status: :ready, refreshed_at: now})
        |> Map.put(:last_refreshed_at, now)

      %{state | refresh: refresh}
    end)
  end

  @spec selected_records(View.State.t() | map | nil, list | nil) :: list
  def selected_records(state, records) when is_list(records) do
    selected_ids =
      state
      |> normalize()
      |> Map.get(:selected, [])
      |> Enum.map(&to_string/1)
      |> MapSet.new()

    Enum.filter(records, &(to_string(Map.get(&1, :id)) in selected_ids))
  end

  def selected_records(_state, _records), do: []

  defp next_selection(_current, %{"operation" => "clear"}), do: []

  defp next_selection(current, %{"operation" => operation, "id" => id}) do
    current_ids = Enum.map(current || [], &to_string/1)

    case operation do
      "set" -> [id]
      "add" -> Enum.uniq(current_ids ++ [id])
      "remove" -> Enum.reject(current_ids, &(&1 == id))
      _ -> toggle_id(current_ids, id)
    end
  end

  defp next_selection(current, %{"id" => id}) do
    toggle_id(Enum.map(current || [], &to_string/1), id)
  end

  defp next_selection(current, _params), do: current || []

  defp toggle_id(current_ids, id) do
    if id in current_ids do
      Enum.reject(current_ids, &(&1 == id))
    else
      current_ids ++ [id]
    end
  end

  defp workflow_transition(%{"event" => event}), do: event
  defp workflow_transition(%{event: event}), do: event
  defp workflow_transition(_params), do: nil

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp normalize_key(key), do: key
end
