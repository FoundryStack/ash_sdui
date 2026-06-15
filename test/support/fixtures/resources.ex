defmodule AshSDUI.TestFixtures.FormResource do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  attributes do
    uuid_primary_key(:id)

    attribute :title, :string do
      allow_nil?(false)
    end

    attribute :body, :string do
      allow_nil?(false)
    end

    attribute(:email, :string)
    attribute(:internal_note, :string)
  end

  actions do
    create :create do
      accept([:title, :body, :email, :internal_note])
    end
  end

  sdui do
    default_component("Form.Card@v1")
    ui_field(:title, label: "Title", order: 1)
    ui_field(:body, label: "Body", order: 2, widget: :textarea)
    ui_field(:email, label: "Email", order: 3, widget: :email)
    ui_field(:internal_note, label: "Internal", order: 4, hidden: true)
  end
end

defmodule AshSDUI.TestFixtures.ComponentFormResource do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  attributes do
    uuid_primary_key(:id)
    attribute(:body, :string)
  end

  actions do
    create :create do
      accept([:body])
    end
  end

  sdui do
    default_component("Component.Form@v1")
    ui_field(:body, field_component: ExampleFieldComponent)
  end
end

defmodule AshSDUI.TestFixtures.MockPlayerResource do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
    default_component("Player.Card@v1")
  end
end

defmodule AshSDUI.TestFixtures.MockResourceWithoutComponent do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
  end
end

defmodule AshSDUI.TestFixtures.ScreenArticle do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  attributes do
    uuid_primary_key(:id)

    attribute :title, :string do
      allow_nil?(false)
    end

    attribute :body, :string do
      allow_nil?(false)
    end

    attribute(:internal_notes, :string)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:title, :body, :internal_notes])
    end

    update :update do
      accept([:title, :body])
    end
  end

  sdui do
    default_component("Article.Card@v1")

    ui_intent(:create, style: :primary, label: "New Article", target: {:ash_action, :create})
    ui_intent(:update, style: :secondary, label: "Edit", target: {:ash_action, :update})
    ui_intent(:destroy, style: :destructive, label: "Delete", target: {:ash_action, :destroy})

    ui_field(:title, label: "Title", order: 1)
    ui_field(:body, label: "Body", order: 2, widget: :textarea)
    ui_field(:internal_notes, label: "Internal", order: 3)
  end
end

defmodule AshSDUI.TestFixtures.ScreenArticleUI do
  use AshSDUI.Resource.Standalone

  sdui do
    for_resource(AshSDUI.TestFixtures.ScreenArticle)
    default_component("Article.Card@v1")

    view(:index, recipe: :collection, read_action: :read, title: "Articles")
    view(:show, recipe: :detail, read_action: :read)
    view(:new, recipe: :form, action: :create)

    ui_intent(:create,
      style: :primary,
      label: "New Article",
      target: {:navigate, "/articles/new"},
      placement: :toolbar
    )

    ui_intent(:update,
      style: :secondary,
      label: "Edit",
      target: {:navigate, "/articles/:id/edit"},
      placement: :row,
      requires_actor?: true
    )

    ui_field(:title, label: "Title", order: 1, index?: true, show?: true, form?: true)

    ui_field(:body,
      label: "Body",
      order: 2,
      widget: :textarea,
      index?: false,
      show?: true,
      form?: true
    )

    ui_field(:internal_notes,
      label: "Internal",
      order: 3,
      index?: false,
      show?: true,
      form?: false,
      format: :badge,
      badge?: true
    )
  end
end

defmodule AshSDUI.TestFixtures.LiveResourcePost do
  use Ash.Resource,
    domain: AshSDUI.TestFixtures.LiveResourceBlog,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, allow_nil?: false)
  end

  actions do
    defaults([:read])

    create :create do
      accept([:title])
    end
  end
end

defmodule AshSDUI.TestFixtures.LiveResourceBlog do
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(AshSDUI.TestFixtures.LiveResourcePost)
  end
end

defmodule AshSDUI.TestFixtures.LiveResourcePostUI do
  use AshSDUI.Resource.Standalone

  sdui do
    for_resource(AshSDUI.TestFixtures.LiveResourcePost)
    view(:index, recipe: :collection, read_action: :read, title: "Posts")
    ui_intent(:create, style: :primary, label: "New Post", target: {:navigate, "/posts/new"})
    ui_field(:title, label: "Title", index?: true)
  end
end

defmodule AshSDUI.TestFixtures.TestLayoutResource do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
    default_component("Test.Card@v1")
  end
end

defmodule AshSDUI.TestFixtures.SDUIRootTenantPost do
  use Ash.Resource,
    domain: AshSDUI.TestFixtures.SDUIRootPolicyDomain,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, allow_nil?: false)
    attribute(:account_id, :string, allow_nil?: false, public?: true)
  end

  actions do
    read :read do
      primary?(true)
    end

    create :create do
      primary?(true)
      accept([:title, :account_id])
    end
  end

  multitenancy do
    strategy(:attribute)
    attribute(:account_id)
  end
end

defmodule AshSDUI.TestFixtures.SDUIRootPolicyDomain do
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(AshSDUI.TestFixtures.SDUIRootTenantPost)
  end
end

defmodule AshSDUI.TestFixtures.CustomNodeResource do
  use Ash.Resource,
    domain: AshSDUI.TestFixtures.CustomNodeDomain,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:component_name, :string, allow_nil?: false)
    attribute(:static_props, :map, default: %{})
    attribute(:subject_resource, :string)
    attribute(:subject_id, :string)
    attribute(:region, :atom, default: :default)
    attribute(:order, :integer, default: 0)
    attribute(:status, :atom, allow_nil?: false, default: :draft)
    attribute(:name, :string)
  end

  relationships do
    belongs_to(:parent, __MODULE__)
    has_many(:children, __MODULE__, destination_attribute: :parent_id)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :component_name,
        :static_props,
        :subject_resource,
        :subject_id,
        :region,
        :order,
        :status,
        :name,
        :parent_id
      ])
    end

    update :update do
      accept([
        :component_name,
        :static_props,
        :subject_resource,
        :subject_id,
        :region,
        :order,
        :status,
        :name,
        :parent_id
      ])
    end

    update :publish do
      change(set_attribute(:status, :published))
    end
  end
end

defmodule AshSDUI.TestFixtures.CustomNodeDomain do
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(AshSDUI.TestFixtures.CustomNodeResource)
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.Basic do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
    default_component("Card@v1")
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.WithDefault do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
    default_component("Player.Profile@v2")
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.NoDefault do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.WithActions do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  attributes do
    attribute(:id, :uuid,
      primary_key?: true,
      default: &Ecto.UUID.generate/0,
      allow_nil?: false
    )
  end

  actions do
    action(:create)
    action(:update)
    action(:delete)
  end

  sdui do
    ui_intent(:create, style: :primary, label: "New Player", icon: "plus")
    ui_intent(:update, style: :secondary)
    ui_intent(:delete, style: :destructive, icon: "trash")
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.ActionDefaults do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  attributes do
    attribute(:id, :uuid,
      primary_key?: true,
      default: &Ecto.UUID.generate/0,
      allow_nil?: false
    )
  end

  actions do
    action(:view)
  end

  sdui do
    ui_intent(:view)
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.ActionAttrs do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  attributes do
    attribute(:id, :uuid,
      primary_key?: true,
      default: &Ecto.UUID.generate/0,
      allow_nil?: false
    )
  end

  actions do
    action(:submit)
  end

  sdui do
    ui_intent(:submit, label: "Send Form", icon: "send")
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.WithAttrs do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
    ui_field(:name, label: "Player Name", order: 1)
    ui_field(:email, label: "Email Address", order: 2, hidden: true)
    ui_field(:created_at)
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.AttrDefaults do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
    ui_field(:status)
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.AttrWidget do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
    ui_field(:body, widget: :textarea)
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.LabelKey do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  attributes do
    attribute(:id, :uuid,
      primary_key?: true,
      default: &Ecto.UUID.generate/0,
      allow_nil?: false
    )
  end

  actions do
    action(:create)
  end

  sdui do
    ui_intent(:create, label_key: "player.action.create", icon: "plus")
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.AttrLabelKey do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
    ui_field(:name, label_key: "player.name")
    ui_field(:score, label: "High Score")
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.GettextResource do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
    gettext_backend(SduiDemo.Gettext)
    gettext_domain("myapp")
  end
end

defmodule AshSDUI.TestFixtures.ResourceExtension.DefaultDomainResource do
  use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

  sdui do
  end
end

defmodule AshSDUI.TestFixtures.ViewArticleUI do
  use AshSDUI.Resource.Standalone

  sdui do
    for_resource(AshSDUI.TestFixtures.ScreenArticle)
    default_component("Article.Card@v1")

    view(:index, recipe: :collection, read_action: :read, title: "Knowledge Base", query: :default)
    view(:show, recipe: :detail, read_action: :read)
    view(:new, recipe: :form, action: :create)

    ui_query(:default,
      search: [:title],
      sort: [:title],
      filters: [:title],
      default_sort: [title: :asc],
      default_limit: 25
    )

    ui_binding(:collection,
      source: {:resource, AshSDUI.TestFixtures.ScreenArticle},
      many?: true,
      query: :default
    )

    ui_binding(:record,
      source: {:resource, AshSDUI.TestFixtures.ScreenArticle},
      many?: false
    )

    ui_intent(:create,
      style: :primary,
      label: "New Article",
      target: {:navigate, "/articles/new"},
      placement: :toolbar
    )

    ui_intent(:update,
      style: :secondary,
      label: "Edit",
      target: {:ash_action, :update},
      placement: :row,
      requires_actor?: true
    )

    ui_field(:title,
      label: "Title",
      order: 1,
      index?: true,
      show?: true,
      form?: true,
      filter?: true,
      sortable?: true,
      binding: :collection
    )

    ui_field(:body,
      label: "Body",
      order: 2,
      widget: :textarea,
      index?: false,
      show?: true,
      form?: true,
      binding: :record
    )
  end
end
