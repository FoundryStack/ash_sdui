defmodule AshSDUI.Resource.Info do
  @moduledoc """
  Introspection API for AshSDUI.Resource DSL extensions.

  Works with both inline Ash extensions and standalone UI modules.
  """

  require Spark.Dsl.Extension

  @doc "Reads the `:default_component` option from the sdui block, or nil."
  def default_component(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:sdui], :default_component, nil)
  end

  @doc """
  Returns the Ash resource this module annotates.

  For inline Ash extensions, returns the module itself.
  For standalone UI modules (`use AshSDUI.Resource.Standalone`), returns the `for_resource`.
  """
  def for_resource(module) do
    Spark.Dsl.Extension.get_opt(module, [:sdui], :for_resource, module)
  end

  @doc "Reads all `ui_action` entities from the sdui block, or []."
  def ui_actions(resource) do
    (Spark.Dsl.Extension.get_entities(resource, [:sdui]) || [])
    |> Enum.filter(&is_struct(&1, AshSDUI.Resource.UiAction))
  end

  @doc "Reads all `ui_attribute` entities from the sdui block, or []."
  def ui_attributes(resource) do
    (Spark.Dsl.Extension.get_entities(resource, [:sdui]) || [])
    |> Enum.filter(&is_struct(&1, AshSDUI.Resource.UiAttribute))
  end
end
