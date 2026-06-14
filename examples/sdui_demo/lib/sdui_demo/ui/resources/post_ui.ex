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

    screen(:index,
      recipe: :editorial_blog,
      read_action: :read,
      layout: :sdui,
      title: "AshSDUI Journal"
    )
    screen(:show, recipe: :detail, read_action: :read)
    screen(:new, recipe: :form, action: :create)
    screen(:edit, recipe: :form, action: :update)

    ui_action(:create,
      intent: :primary,
      label_key: "post.action.create",
      icon: "file-plus",
      kind: :link,
      to: "/posts/new",
      placement: :toolbar
    )

    ui_action(:read,
      intent: :primary,
      label: "Read",
      icon: "book-open",
      kind: :link,
      to: "/posts/:id",
      placement: :row
    )

    ui_action(:update,
      intent: :secondary,
      label_key: "post.action.update",
      icon: "pencil",
      kind: :link,
      to: "/posts/:id/edit",
      placement: :row
    )

    ui_action(:publish, intent: :info, label_key: "post.action.publish", icon: "send")

    ui_action(:destroy,
      intent: :destructive,
      label_key: "post.action.destroy",
      icon: "trash",
      kind: :event,
      event: "delete",
      confirm: "Delete this post?",
      placement: :row
    )

    ui_attribute(:title,
      label_key: "post.title",
      order: 1,
      widget: :text_input,
      index?: true,
      show?: true,
      form?: true
    )

    ui_attribute(:body,
      label_key: "post.body",
      order: 2,
      widget: :textarea,
      field_component: SduiDemoWeb.Components.PostPublishHintField,
      index?: false,
      show?: true,
      form?: true
    )

    ui_attribute(:published_at,
      label_key: "post.published_at",
      order: 3,
      hidden: false,
      index?: true,
      show?: true,
      form?: false
    )
  end
end
