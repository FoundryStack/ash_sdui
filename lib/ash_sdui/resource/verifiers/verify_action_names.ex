defmodule AshSDUI.Resource.Verifiers.VerifyActionNames do
  @moduledoc false
  use Spark.Dsl.Verifier

  require Spark.Dsl.Extension

  def verify(dsl_state) do
    intents =
      (Spark.Dsl.Extension.get_entities(dsl_state, [:sdui]) || [])
      |> Enum.flat_map(fn
        %AshSDUI.Resource.UiIntent{target: {:ash_action, action}} when is_atom(action) -> [action]
        %AshSDUI.Resource.UiIntent{name: name, target: nil} when is_atom(name) -> [name]
        _other -> []
      end)

    module = Spark.Dsl.Verifier.get_persisted(dsl_state, :module)

    # In standalone mode, for_resource points to the domain resource to validate against.
    # In Ash extension mode, the module itself is the resource.
    for_resource = Spark.Dsl.Extension.get_opt(dsl_state, [:sdui], :for_resource, nil)
    resource = for_resource || module

    if Ash.Resource.Info.resource?(resource) do
      defined_action_names =
        resource |> Ash.Resource.Info.actions() |> Enum.map(& &1.name) |> MapSet.new()

      intents
      |> Enum.uniq()
      |> Enum.reject(&MapSet.member?(defined_action_names, &1))
      |> Enum.each(&raise_error(&1, resource))
    end

    :ok
  end

  defp raise_error(action_name, resource) do
    raise Spark.Error.DslError,
      path: [:sdui, :ui_intent],
      module: resource,
      message:
        "ui intent/action `:#{action_name}` is not defined on resource #{inspect(resource)}"
  end
end
