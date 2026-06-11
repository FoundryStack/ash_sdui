defmodule AshSDUI.Resource.Transformers.RegisterComponent do
  @moduledoc false
  use Spark.Dsl.Transformer

  def transform(dsl_state) do
    component_name =
      Spark.Dsl.Transformer.get_option(dsl_state, [:sdui], :default_component)

    if component_name do
      {:ok, Spark.Dsl.Transformer.eval(dsl_state, [],
        quote do
          def __ash_sdui_auto_register__, do: unquote(component_name)
        end
      )}
    else
      {:ok, dsl_state}
    end
  end
end
