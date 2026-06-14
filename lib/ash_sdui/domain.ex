defmodule AshSDUI.Domain do
  @moduledoc false

  use Ash.Domain,
    validate_config_inclusion?: false

  resources do
    resource(AshSDUI.UINode)
    resource(AshSDUI.UINode.Version)
  end
end
