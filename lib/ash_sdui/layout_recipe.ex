defmodule AshSDUI.LayoutRecipe do
  @moduledoc """
  Behaviour for converting resolved views into SDUI layout trees.

  Recipes are the extensibility point behind higher-level layout names. The core
  package can ship convenient recipes, while applications can register their own
  without changing AshSDUI internals.
  """

  alias AshSDUI.Layout
  alias AshSDUI.View

  @callback to_layout(View.t(), keyword) :: Layout.Node.t()
end

defmodule AshSDUI.LayoutRecipe.Registry do
  @moduledoc """
  Registry for layout recipe modules.

  Recipe names are app-level vocabulary. AshSDUI only requires that a recipe
  module implements `AshSDUI.LayoutRecipe`.
  """

  @registry_key {__MODULE__, :recipes}

  @default_recipes %{
    index: AshSDUI.Recipes.GenericResource,
    show: AshSDUI.Recipes.GenericResource,
    new: AshSDUI.Recipes.GenericResource,
    edit: AshSDUI.Recipes.GenericResource,
    collection: AshSDUI.Recipes.GenericResource,
    detail: AshSDUI.Recipes.GenericResource,
    form: AshSDUI.Recipes.GenericResource
  }

  @doc "Registers or replaces a recipe module under a name."
  @spec register(atom, module) :: :ok
  def register(name, module) when is_atom(name) and is_atom(module) do
    :persistent_term.put(@registry_key, Map.put(all_map(), name, module))
    :ok
  end

  @doc "Fetches a recipe module by name."
  @spec fetch(atom) :: {:ok, module} | {:error, {:unknown_recipe, atom}}
  def fetch(name) when is_atom(name) do
    case Map.fetch(all_map(), name) do
      {:ok, module} -> {:ok, module}
      :error -> {:error, {:unknown_recipe, name}}
    end
  end

  @doc "Returns all registered recipes including built-ins."
  @spec all :: %{atom => module}
  def all, do: all_map()

  defp all_map do
    Map.merge(@default_recipes, :persistent_term.get(@registry_key, %{}))
  end
end
