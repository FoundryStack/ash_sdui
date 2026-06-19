defmodule AshSDUI.Runtime.Meta do
  @moduledoc """
  Shared helpers for the persisted node runtime metadata envelope.
  """

  alias AshSDUI.Layout.Node
  alias AshSDUI.Runtime.Normalize

  @runtime_meta_key "__ash_sdui__"
  @runtime_meta_keys [@runtime_meta_key, String.to_atom(@runtime_meta_key)]

  @spec embed(Node.t() | map, map | nil) :: map
  def embed(node_or_props, runtime_meta_or_props \\ nil)

  def embed(%Node{} = node, static_props) do
    static_props = static_props || node.static_props || %{}

    runtime_meta =
      %{}
      |> maybe_put(:refresh, node.refresh)
      |> maybe_put(:binding, node.binding)
      |> maybe_put(:variant, node.variant)
      |> maybe_put(:state_key, node.state_key)

    embed(static_props, runtime_meta)
  end

  def embed(static_props, runtime_meta) do
    static_props = Normalize.mapify(static_props)
    runtime_meta = normalize(runtime_meta)

    if runtime_meta == %{} do
      static_props
    else
      Map.put(static_props, @runtime_meta_key, runtime_meta)
    end
  end

  @spec split(map | nil) :: {map, map}
  def split(static_props) do
    static_props = Normalize.mapify(static_props)

    runtime_meta =
      Map.get(static_props, @runtime_meta_key) ||
        Map.get(static_props, String.to_atom(@runtime_meta_key)) ||
        %{}

    {Map.drop(static_props, @runtime_meta_keys), normalize(runtime_meta)}
  end

  @spec normalize(map | nil | term) :: map
  def normalize(runtime_meta) when is_map(runtime_meta) do
    %{
      refresh: read(runtime_meta, :refresh),
      binding: read(runtime_meta, :binding),
      variant: read(runtime_meta, :variant),
      state_key: read(runtime_meta, :state_key)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end

  def normalize(_runtime_meta), do: %{}

  @spec read(map, atom) :: term
  def read(meta, key) do
    Map.get(meta, key) || Map.get(meta, Atom.to_string(key))
  end

  defp maybe_put(meta, _key, nil), do: meta
  defp maybe_put(meta, key, value), do: Map.put(meta, key, value)
end
