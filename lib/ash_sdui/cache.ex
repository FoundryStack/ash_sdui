defmodule AshSDUI.Cache do
  @moduledoc """
  ETS-backed cache for UI graph trees. Subscribes to UINode change notifications
  and evicts affected graphs on any create/update/destroy event.
  """

  use GenServer

  @table __MODULE__

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get(name) do
    ensure_table!()

    case :ets.lookup(@table, name) do
      [{^name, tree}] -> {:ok, tree}
      [] -> {:error, :not_found}
    end
  end

  def put(name, tree) do
    ensure_table!()
    :ets.insert(@table, {name, tree})
    :ok
  end

  def evict(name) do
    ensure_table!()
    :ets.delete(@table, name)
    :ok
  end

  def evict_for_node(%{name: name}) when is_binary(name) do
    evict(name)
  end

  def evict_for_node(%{parent_id: nil, name: name}) when is_binary(name) do
    evict(name)
  end

  def evict_for_node(_node) do
    # Evict all when we can't determine the root
    ensure_table!()
    :ets.delete_all_objects(@table)
    :ok
  end

  def flush do
    ensure_table!()
    :ets.delete_all_objects(@table)
    :ok
  end

  @impl true
  def init(_) do
    ensure_table!()
    {:ok, %{}}
  end

  defp ensure_table! do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, read_concurrency: true])
        :ok

      _table ->
        :ok
    end
  rescue
    ArgumentError ->
      :ok
  end
end
