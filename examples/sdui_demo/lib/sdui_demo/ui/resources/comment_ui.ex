defmodule SduiDemo.UI.Resources.CommentUI do
  @moduledoc """
  SDUI UI metadata for the Comment domain resource.

  Comments are typically rendered as children inside a PostCard via the
  `:comments` region. The default component is CommentItem@v1.
  """

  use AshSDUI.Resource.Standalone

  sdui do
    for_resource(SduiDemo.Blog.Comment)
    default_component("CommentItem@v1")
    gettext_backend(SduiDemo.Gettext)

    view(:index, recipe: :collection, read_action: :read, title: "Comments")
    view(:show, recipe: :detail, read_action: :read)

    ui_binding(:collection, source: {:resource, SduiDemo.Blog.Comment}, many?: true)
    ui_binding(:record, source: {:resource, SduiDemo.Blog.Comment}, many?: false)

    ui_intent(:create, style: :primary, label_key: "comment.action.create", icon: "message-plus")
    ui_intent(:update, style: :secondary, label_key: "comment.action.update", icon: "pencil")
    ui_intent(:destroy, style: :destructive, label_key: "comment.action.destroy", icon: "trash")

    ui_field(:body, label_key: "comment.body", order: 1, widget: :textarea)
    ui_field(:posted_at, label_key: "comment.posted_at", order: 2)
  end
end
