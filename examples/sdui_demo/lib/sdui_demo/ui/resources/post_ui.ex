defmodule SduiDemo.UI.Resources.PostUI do
  @moduledoc """
  SDUI UI metadata for the Post domain resource.

  Annotates how posts are displayed and what actions are available.
  The default component renders a post with its author card and comment list as children.
  """

  use AshSDUI.Resource.Standalone

  sdui do
    for_resource(SduiDemo.Blog.Post)
    default_component("PostCard@v1")
    gettext_backend(SduiDemo.Gettext)

    view(:index,
      recipe: :editorial_blog,
      read_action: :read,
      layout: :sdui,
      title: "AshSDUI Journal",
      query: :default
    )

    view(:show, recipe: :detail, read_action: :read)
    view(:new, recipe: :form, action: :create)
    view(:edit, recipe: :form, action: :update)

    ui_query(:default,
      search: [:title, :body],
      sort: [:title, :published_at],
      filters: [:title],
      default_sort: [published_at: :desc],
      default_limit: 10
    )

    ui_binding(:collection, source: {:resource, SduiDemo.Blog.Post}, many?: true, query: :default)
    ui_binding(:record, source: {:resource, SduiDemo.Blog.Post}, many?: false, default: %{})

    ui_intent(:create,
      style: :primary,
      label_key: "post.action.create",
      icon: "file-plus",
      target: {:navigate, "/posts/new"},
      placement: :toolbar
    )

    ui_intent(:read,
      style: :primary,
      label: "Read",
      icon: "book-open",
      target: {:navigate, "/posts/:id"},
      placement: :row
    )

    ui_intent(:update,
      style: :secondary,
      label_key: "post.action.update",
      icon: "pencil",
      target: {:navigate, "/posts/:id/edit"},
      placement: :row
    )

    ui_intent(:publish,
      style: :info,
      label_key: "post.action.publish",
      icon: "send",
      target: {:event, "publish"}
    )

    ui_intent(:destroy,
      style: :destructive,
      label_key: "post.action.destroy",
      icon: "trash",
      target: {:event, "delete"},
      confirm: "Delete this post?",
      placement: :row
    )

    ui_field(:title,
      label_key: "post.title",
      order: 1,
      widget: :text_input,
      index?: true,
      show?: true,
      form?: true,
      filter?: true,
      sortable?: true
    )

    ui_field(:body,
      label_key: "post.body",
      order: 2,
      widget: :textarea,
      field_component: SduiDemoWeb.Components.PostPublishHintField,
      index?: false,
      show?: true,
      form?: true
    )

    ui_field(:published_at,
      label_key: "post.published_at",
      order: 3,
      hidden: false,
      index?: true,
      show?: true,
      form?: false,
      sortable?: true
    )
  end
end
