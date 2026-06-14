defmodule AshSDUI.Resource.Verifiers.VerifyActionNames do
  @moduledoc false
  use Spark.Dsl.Verifier

  require Spark.Dsl.Extension

  def verify(dsl_state) do
    ui_actions = Spark.Dsl.Extension.get_entities(dsl_state, [:sdui]) || []
    ui_actions = Enum.filter(ui_actions, &is_struct(&1, AshSDUI.Resource.UiAction))

    module = Spark.Dsl.Verifier.get_persisted(dsl_state, :module)

    # In standalone mode, for_resource points to the domain resource to validate against.
    # In Ash extension mode, the module itself is the resource.
    for_resource = Spark.Dsl.Extension.get_opt(dsl_state, [:sdui], :for_resource, nil)
    resource = for_resource || module

    if Ash.Resource.Info.resource?(resource) do
      defined_action_names =
        resource |> Ash.Resource.Info.actions() |> Enum.map(& &1.name) |> MapSet.new()

      ui_actions
      |> Enum.filter(&(&1.name not in defined_action_names))
      |> Enum.each(&raise_error(&1, resource))
    end

    :ok
  end

  defp raise_error(ui_action, resource) do
    raise Spark.Error.DslError,
      path: [:sdui, :ui_action],
      module: resource,
      message: "ui_action `:#{ui_action.name}` is not defined on resource #{inspect(resource)}"
  end
end
