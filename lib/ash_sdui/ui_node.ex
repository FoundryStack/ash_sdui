defmodule AshSDUI.UINode do
  @moduledoc """
  Core Ash Resource representing a single node in the UI graph.

  This built-in resource uses the ETS data layer, which is useful for tests,
  demos, and local prototypes. Production applications that need database-backed
  layout storage should define a compatible Ash resource and pass it as
  `node_resource:` to `AshSDUI.Layout` or `use AshSDUI`.
  """

  use Ash.Resource,
    domain: AshSDUI.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshPaperTrail.Resource],
    notifiers: [AshSDUI.Notifier]

  ets do
    private?(true)
  end

  paper_trail do
    change_tracking_mode(:changes_only)
    store_action_name?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :component_name, :string do
      allow_nil?(false)
      constraints(match: ~r/^[A-Za-z0-9\.]+@v\d+$/)
    end

    attribute(:static_props, :map, default: %{})

    attribute(:subject_resource, :string)
    attribute(:subject_id, :string)

    attribute(:region, :atom, default: :default)
    attribute(:order, :integer, default: 0)

    attribute :status, :atom do
      allow_nil?(false)
      default(:draft)
      constraints(one_of: [:draft, :published, :archived])
    end

    attribute(:name, :string)

    timestamps()
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

    update :revert do
      change(set_attribute(:status, :archived))
    end
  end
end
