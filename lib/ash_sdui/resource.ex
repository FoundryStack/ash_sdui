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
        doc: "Display label for the action (takes precedence over label_key)"
      ],
      label_key: [
        type: :string,
        doc:
          "Gettext message key for the action label (resolved at runtime via configured backend)"
      ],
      icon: [
        type: :string,
        doc: "Icon name or identifier"
      ],
      component_override: [
        type: :string,
        doc: "Optional component name to render this action differently"
      ],
      kind: [
        type: {:one_of, [:link, :event, :submit]},
        doc: "Default interaction kind when rendering the action"
      ],
      to: [
        type: :string,
        doc: "Route template or static path for link actions"
      ],
      event: [
        type: :string,
        doc: "LiveView event name for event actions"
      ],
      confirm: [
        type: {:or, [:boolean, :string]},
        doc: "Confirmation flag or message for destructive/event actions"
      ],
      placement: [
        type: :atom,
        doc: "Preferred placement such as :toolbar, :row, :form_footer, or :inline"
      ],
      requires_actor?: [
        type: :boolean,
        default: false,
        doc: "Whether this action should be hidden when no actor is present"
      ],
      visible_when: [
        type: :atom,
        doc: "Named application predicate used by variant resolvers"
      ]
    ]
  }

  @screen %Spark.Dsl.Entity{
    name: :screen,
    describe: "Screen-level presentation metadata",
    examples: ["screen :index, recipe: :card_grid, read_action: :read"],
    args: [:name],
    target: AshSDUI.Resource.Screen,
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "Screen name such as :index, :show, :new, or :edit"
      ],
      recipe: [
        type: :atom,
        doc: "Layout recipe used to render this screen"
      ],
      action: [
        type: :atom,
        doc: "Ash action backing this screen"
      ],
      read_action: [
        type: :atom,
        doc: "Read action backing index/show style screens"
      ],
      layout: [
        type: :atom,
        doc: "Optional named app layout hint"
      ],
      title: [
        type: :string,
        doc: "Default screen title"
      ],
      empty_state: [
        type: :string,
        doc: "Default empty state copy"
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
        doc: "Display label (takes precedence over label_key)"
      ],
      label_key: [
        type: :string,
        doc:
          "Gettext message key for the attribute label (resolved at runtime via configured backend)"
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
      widget: [
        type: {:one_of, [:text_input, :textarea, :email, :checkbox, :datetime]},
        doc: "Preferred form widget when this attribute is rendered in a generated form"
      ],
      field_component: [
        type: :atom,
        doc: "Optional Phoenix component module used to render this field in generated forms"
      ],
      show?: [
        type: :boolean,
        doc: "Whether to show this attribute on detail screens"
      ],
      index?: [
        type: :boolean,
        doc: "Whether to show this attribute on collection screens"
      ],
      form?: [
        type: :boolean,
        doc: "Whether to show this attribute on form screens"
      ],
      filter?: [
        type: :boolean,
        default: false,
        doc: "Whether this attribute can be used as a generated filter"
      ],
      sortable?: [
        type: :boolean,
        default: false,
        doc: "Whether this attribute can be used as a generated sort"
      ],
      format: [
        type: :atom,
        doc: "Named formatter hint such as :relative_datetime, :currency, or :badge"
      ],
      empty_state: [
        type: :string,
        doc: "Fallback text when this field is blank"
      ],
      badge?: [
        type: :boolean,
        default: false,
        doc: "Whether this field prefers badge-style rendering"
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
      ],
      gettext_backend: [
        type: :atom,
        doc: "Gettext backend module for resolving label_key values (e.g. MyApp.Gettext)"
      ],
      gettext_domain: [
        type: :string,
        default: "sdui",
        doc: "Gettext domain for label_key lookups (default: \"sdui\")"
      ]
    ],
    entities: [@screen, @ui_action, @ui_attribute]
  }

  use Spark.Dsl.Extension,
    sections: [@sdui],
    verifiers: [AshSDUI.Resource.Verifiers.VerifyActionNames],
    transformers: [AshSDUI.Resource.Transformers.RegisterComponent]
end
