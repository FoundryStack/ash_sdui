defmodule SduiDemo.Blog.Post do
  use Ash.Resource,
    domain: SduiDemo.Blog,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :title, :string do
      allow_nil?(false)
    end

    attribute :body, :string do
      allow_nil?(false)
    end

    attribute(:author_id, :uuid)
    attribute(:published_at, :utc_datetime)
  end

  relationships do
    belongs_to :author, SduiDemo.Accounts.User do
      source_attribute(:author_id)
      define_attribute?(false)
    end

    has_many :comments, SduiDemo.Blog.Comment do
      destination_attribute(:post_id)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:title, :body, :author_id, :published_at])
    end

    update :update do
      accept([:title, :body, :published_at])
    end

    update :publish do
      accept([])
      change(set_attribute(:published_at, &DateTime.utc_now/0))
    end
  end
end
