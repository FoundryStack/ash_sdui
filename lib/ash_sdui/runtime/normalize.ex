defmodule AshSDUI.Runtime.Normalize do
  @moduledoc """
  Small normalization helpers shared across the runtime.
  """

  @spec mapify(map | keyword | nil | term) :: map
  def mapify(nil), do: %{}
  def mapify(map) when is_map(map), do: map
  def mapify(list) when is_list(list), do: Enum.into(list, %{})
  def mapify(_value), do: %{}

  @spec maybe_put_keyword(keyword, atom, term) :: keyword
  def maybe_put_keyword(opts, _key, nil), do: opts
  def maybe_put_keyword(opts, key, value), do: Keyword.put(opts, key, value)

  @spec maybe_put_map(map, term, term) :: map
  def maybe_put_map(map, _key, nil), do: map
  def maybe_put_map(map, _key, ""), do: map
  def maybe_put_map(map, _key, value) when value == %{}, do: map
  def maybe_put_map(map, key, value), do: Map.put(map, key, value)
end
