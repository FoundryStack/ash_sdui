defmodule AshSDUI.Resource do
  @moduledoc """
  Spark DSL extension for annotating Ash Resources with SDUI metadata.

  ## Usage as an Ash extension (inline annotations)

      use Ash.Resource, extensions: [AshSDUI.Resource]

      sdui do
        default_component "Player.Card@v1"
        ui_action :create, intent: :primary, label: "New Player"
        ui_attribute :name, label: "Player Name"
      end

  ## Usage as a standalone UI metadata module (separation of concerns)

      defmodule MyApp.UI.Resources.PlayerUI do
        use AshSDUI.Resource.Standalone

        sdui do
          for_resource MyApp.Player
          default_component "Player.Card@v1"
          ui_action :create, intent: :primary, label: "New Player"
          ui_attribute :name, label: "Player Name"
        end
      end

  The standalone form keeps domain resources free of UI concerns. The `for_resource`
  declaration is used by the verifier to validate action names and by the storybook
  integration.

  See `AshSDUI.Resource.Info` for introspection API.
  """

  @ui_action %Spark.Dsl.Entity{
    name: :ui_action,
    describe: "UI action metadata",
    examples: ["ui_action :create, intent: :primary, label: \"New Player\""],
    args: [:name],
    target: AshSDUI.Resource.UiAction,
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "Action name (must exist on the resource)"
      ],
      intent: [
        type: {:one_of, [:primary, :secondary, :destructive, :info]},
        default: :secondary,
        doc: "Visual intent: primary, secondary, destructive, or info"
      ],
      label: [
        type: :string,
        doc: "Display label for the action"
      ],
      icon: [
        type: :string,
        doc: "Icon name or identifier"
      ],
      component_override: [
        type: :string,
        doc: "Optional component name to render this action differently"
      ]
    ]
  }

  @ui_attribute %Spark.Dsl.Entity{
    name: :ui_attribute,
    describe: "UI attribute metadata",
    examples: ["ui_attribute :name, label: \"Player Name\", order: 1"],
    args: [:name],
    target: AshSDUI.Resource.UiAttribute,
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "Attribute name"
      ],
      label: [
        type: :string,
        doc: "Display label"
      ],
      icon: [
        type: :string,
        doc: "Icon name or identifier"
      ],
      hidden: [
        type: :boolean,
        default: false,
        doc: "Whether to hide this attribute by default"
      ],
      order: [
        type: :non_neg_integer,
        default: 0,
        doc: "Display order (lower first)"
      ]
    ]
  }

  @sdui %Spark.Dsl.Section{
    name: :sdui,
    describe: "SDUI component registration and UI metadata",
    schema: [
      default_component: [
        type: :string,
        doc: "Name of the default SDUI component for this resource"
      ],
      for_resource: [
        type: :atom,
        doc: "The Ash resource this UI module annotates (used in standalone mode)"
      ]
    ],
    entities: [@ui_action, @ui_attribute]
  }

  use Spark.Dsl.Extension,
    sections: [@sdui],
    verifiers: [AshSDUI.Resource.Verifiers.VerifyActionNames],
    transformers: [AshSDUI.Resource.Transformers.RegisterComponent]
end
