defmodule SduiDemo.Blog.Comment do
  use Ash.Resource,
    domain: SduiDemo.Blog,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
  end

  attributes do
    uuid_primary_key :id

    attribute :body, :string do
      allow_nil? false
    end

    attribute :post_id, :uuid
    attribute :author_id, :uuid
    attribute :posted_at, :utc_datetime
  end

  relationships do
    belongs_to :post, SduiDemo.Blog.Post do
      source_attribute :post_id
      define_attribute? false
    end

    belongs_to :author, SduiDemo.Accounts.User do
      source_attribute :author_id
      define_attribute? false
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:body, :post_id, :author_id, :posted_at]
    end

    update :update do
      accept [:body]
    end
  end
end
