defmodule AshSDUI.Resource do
  @moduledoc """
  Spark DSL extension for annotating Ash resources with compact UI metadata.

  ## Usage as an Ash extension

      use Ash.Resource, extensions: [AshSDUI.Resource]

      sdui do
        default_component "Player.Card@v1"
        view :index, recipe: :collection, read_action: :read
        ui_intent :create, style: :primary, target: {:navigate, "/players/new"}
        ui_field :name, label: "Player Name"
      end

  ## Usage as a standalone UI metadata module

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

  See `AshSDUI.Resource.Info` for the introspection API used by generated views.
  """

  @view %Spark.Dsl.Entity{
    name: :view,
    describe: "View-level presentation metadata",
    examples: ["view :index, recipe: :collection, read_action: :read, query: :default"],
    args: [:name],
    target: AshSDUI.Resource.View,
    schema: [
      name: [type: :atom, required: true, doc: "View name such as :index, :show, :new, or :edit"],
      recipe: [type: :atom, doc: "Layout recipe used to render this view"],
      action: [type: :atom, doc: "Ash action backing this view"],
      read_action: [type: :atom, doc: "Read action backing collection/detail views"],
      layout: [type: :atom, doc: "Optional named app layout hint"],
      title: [type: :string, doc: "Default view title"],
      empty_state: [type: :string, doc: "Default empty state copy"],
      query: [type: :atom, doc: "Named query schema used by this view"],
      refresh: [type: :any, doc: "Optional refresh metadata for the view runtime"],
      workflow: [type: :any, doc: "Optional workflow metadata for the view runtime"]
    ]
  }

  @ui_intent %Spark.Dsl.Entity{
    name: :ui_intent,
    describe: "Generic UI intent metadata",
    examples: ["ui_intent :create, style: :primary, target: {:ash_action, :create}"],
    args: [:name],
    target: AshSDUI.Resource.UiIntent,
    schema: [
      name: [type: :atom, required: true, doc: "Intent name"],
      style: [
        type: :atom,
        default: :secondary,
        doc: "Visual style hint such as :primary or :destructive"
      ],
      label: [type: :string, doc: "Display label for the intent"],
      label_key: [type: :string, doc: "Gettext message key for the intent label"],
      icon: [type: :string, doc: "Icon name or identifier"],
      component_override: [
        type: :string,
        doc: "Optional component name to render this intent differently"
      ],
      target: [
        type: :any,
        doc:
          "Intent target such as {:ash_action, :publish}, {:navigate, \"/posts/new\"}, or {:event, \"refresh\"}"
      ],
      confirm: [type: {:or, [:boolean, :string]}, doc: "Confirmation flag or message"],
      placement: [
        type: :atom,
        doc: "Preferred placement such as :toolbar, :row, :form_footer, or :inline"
      ],
      requires_actor?: [
        type: :boolean,
        default: false,
        doc: "Whether this intent should be hidden when no actor is present"
      ],
      visible_when: [type: :atom, doc: "Named application predicate used by variant resolvers"],
      enabled_when: [
        type: :any,
        doc: "Predicate hint for whether the intent should be enabled in the current runtime"
      ],
      loading_when: [
        type: :any,
        doc: "Predicate hint for whether the intent should render in a loading state"
      ],
      refreshes: [
        type: {:list, :atom},
        doc: "Binding names that should refresh after the intent succeeds"
      ]
    ]
  }

  @ui_field %Spark.Dsl.Entity{
    name: :ui_field,
    describe: "Generic UI field metadata",
    examples: ["ui_field :name, label: \"Player Name\", order: 1, binding: :record"],
    args: [:name],
    target: AshSDUI.Resource.UiField,
    schema: [
      name: [type: :atom, required: true, doc: "Field name"],
      label: [type: :string, doc: "Display label (takes precedence over label_key)"],
      label_key: [type: :string, doc: "Gettext message key for the field label"],
      icon: [type: :string, doc: "Icon name or identifier"],
      hidden: [type: :boolean, default: false, doc: "Whether to hide this field by default"],
      widget: [
        type: {:one_of, [:text_input, :textarea, :email, :checkbox, :datetime]},
        doc: "Preferred form widget for generated forms"
      ],
      field_component: [
        type: :atom,
        doc: "Optional Phoenix component module used to render this field"
      ],
      show?: [type: :boolean, doc: "Whether to show this field on detail views"],
      index?: [type: :boolean, doc: "Whether to show this field on collection views"],
      form?: [type: :boolean, doc: "Whether to show this field on form views"],
      filter?: [
        type: :boolean,
        default: false,
        doc: "Whether this field can be used as a generated filter"
      ],
      sortable?: [
        type: :boolean,
        default: false,
        doc: "Whether this field can be used as a generated sort"
      ],
      format: [type: :atom, doc: "Named formatter hint"],
      empty_state: [type: :string, doc: "Fallback text when this field is blank"],
      badge?: [
        type: :boolean,
        default: false,
        doc: "Whether this field prefers badge-style rendering"
      ],
      binding: [type: :atom, doc: "Binding name this field reads from"],
      order: [type: :non_neg_integer, default: 0, doc: "Display order (lower first)"]
    ]
  }

  @ui_binding %Spark.Dsl.Entity{
    name: :ui_binding,
    describe: "Named data binding metadata",
    examples: ["ui_binding :record, source: {:resource, MyApp.Post}"],
    args: [:name],
    target: AshSDUI.Resource.UiBinding,
    schema: [
      name: [type: :atom, required: true, doc: "Binding name"],
      source: [
        type: :any,
        required: true,
        doc:
          "Binding source such as {:resource, MyApp.Post}, {:relationship, :comments}, {:poll, {:resource, MyApp.Post}, interval: 5_000}, {:pubsub, \"posts\", source: {:assign, :seed_posts}, event: :post_update, reducer: :stream_event}, or {:stream, {:assign, :items}, key: :id, reducer: :stream_event}"
      ],
      many?: [type: :boolean, doc: "Whether the binding resolves to many records"],
      query: [type: :atom, doc: "Named query schema applied when loading the binding"],
      default: [type: :any, doc: "Fallback value if the binding cannot be resolved"],
      refresh: [
        type: :any,
        doc: "Refresh policy such as :manual, :params, or {:interval, 5_000}"
      ],
      update: [
        type: :any,
        doc: "Update strategy such as :replace, :append, :merge, or :remove"
      ]
    ]
  }

  @ui_query %Spark.Dsl.Entity{
    name: :ui_query,
    describe: "Named query-state metadata",
    examples: ["ui_query :default, search: [:title], sort: [:inserted_at], filters: [:status]"],
    args: [:name],
    target: AshSDUI.Resource.UiQuery,
    schema: [
      name: [type: :atom, required: true, doc: "Query schema name"],
      search: [type: {:list, :atom}, doc: "Fields supported by full-text search"],
      sort: [type: {:list, :atom}, doc: "Fields supported by generated sorting"],
      filters: [type: {:list, :atom}, doc: "Fields supported by generated filtering"],
      default_sort: [type: :any, doc: "Default sort specification"],
      default_limit: [type: :pos_integer, doc: "Default page size"]
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
      gettext_backend: [type: :atom, doc: "Gettext backend module for resolving label_key values"],
      gettext_domain: [
        type: :string,
        default: "sdui",
        doc: "Gettext domain for label_key lookups"
      ]
    ],
    entities: [@view, @ui_intent, @ui_field, @ui_binding, @ui_query]
  }

  use Spark.Dsl.Extension,
    sections: [@sdui],
    verifiers: [AshSDUI.Resource.Verifiers.VerifyActionNames],
    transformers: [AshSDUI.Resource.Transformers.RegisterComponent]
end
