defmodule AshSDUI.Runtime.RecipeOverrides do
  @moduledoc """
  Shared normalization and lookup helpers for recipe override metadata.
  """

  @spec normalize_recipe_overrides(map | keyword | term) :: map
  def normalize_recipe_overrides(overrides) when is_list(overrides) do
    overrides
    |> Enum.into(%{})
    |> normalize_recipe_overrides()
  end

  def normalize_recipe_overrides(overrides) when is_map(overrides) do
    %{
      fields: normalize_override_map(Map.get(overrides, :fields, %{})),
      intents: normalize_override_map(Map.get(overrides, :intents, %{})),
      toolbar: normalize_override(Map.get(overrides, :toolbar, %{})),
      content: normalize_override(Map.get(overrides, :content, %{})),
      view: normalize_override(Map.get(overrides, :view, %{})),
      title: Map.get(overrides, :title),
      empty_state: normalize_empty_state(Map.get(overrides, :empty_state))
    }
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}] end)
    |> Enum.into(%{})
  end

  def normalize_recipe_overrides(_overrides), do: %{}

  @spec merge_override_maps(map | keyword | term, map | keyword | term) :: map
  def merge_override_maps(base, override) do
    base
    |> normalize_override_map()
    |> Map.merge(normalize_override_map(override))
  end

  @spec recipe_hidden?(map | struct | nil, atom) :: boolean
  def recipe_hidden?(view_or_assigns, section) do
    view_or_assigns
    |> recipe_overrides()
    |> Map.get(section, %{})
    |> Map.get(:skip?, false)
  end

  @spec recipe_class(map | struct | nil, atom) :: String.t() | nil
  def recipe_class(view_or_assigns, section) do
    view_or_assigns
    |> recipe_overrides()
    |> Map.get(section, %{})
    |> Map.get(:props, %{})
    |> Map.get(:class)
  end

  @spec normalize_empty_state(map | keyword | binary | term) :: map
  def normalize_empty_state(nil), do: %{}
  def normalize_empty_state(empty_state) when is_binary(empty_state), do: %{title: empty_state}

  def normalize_empty_state(empty_state) when is_list(empty_state),
    do: Enum.into(empty_state, %{})

  def normalize_empty_state(empty_state) when is_map(empty_state), do: empty_state
  def normalize_empty_state(_empty_state), do: %{}

  @spec normalize_override_map(map | keyword | term) :: map
  def normalize_override_map(overrides) when is_list(overrides) do
    overrides
    |> Enum.into(%{})
    |> normalize_override_map()
  end

  def normalize_override_map(overrides) when is_map(overrides) do
    Map.new(overrides, fn {key, override} ->
      {key, normalize_override(override)}
    end)
  end

  def normalize_override_map(_overrides), do: %{}

  @spec normalize_override(term) :: map
  def normalize_override(false), do: %{skip?: true}
  def normalize_override(nil), do: %{}
  def normalize_override(true), do: %{}
  def normalize_override(override) when is_list(override), do: Enum.into(override, %{})
  def normalize_override(override) when is_map(override), do: override
  def normalize_override(_override), do: %{}

  defp recipe_overrides(%{assigns: assigns}) when is_map(assigns), do: recipe_overrides(assigns)
  defp recipe_overrides(assigns) when is_map(assigns), do: Map.get(assigns, :recipe_overrides, %{})
  defp recipe_overrides(_assigns), do: %{}
end
