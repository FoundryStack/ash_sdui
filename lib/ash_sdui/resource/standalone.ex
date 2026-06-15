defmodule AshSDUI.Resource.Standalone do
  @moduledoc """
  Parent DSL for standalone SDUI resource annotation modules.

  This module enables the `sdui do...end` block in non-Ash modules that exist
  solely to declare UI metadata for a domain resource.

  ## Usage

      defmodule MyApp.UI.Resources.PlayerUI do
        use AshSDUI.Resource.Standalone

        sdui do
          for_resource MyApp.Player
          default_component "Player.Card@v1"
          view :index, recipe: :collection, read_action: :read
          ui_intent :create, style: :primary, target: {:navigate, "/players/new"}
          ui_field :name, label: "Player Name"
        end
      end
  """

  use Spark.Dsl,
    untyped_extensions?: true,
    default_extensions: [extensions: [AshSDUI.Resource]]
end
