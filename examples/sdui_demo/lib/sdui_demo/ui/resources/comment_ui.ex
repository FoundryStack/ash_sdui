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

    ui_action(:create, intent: :primary, label_key: "comment.action.create", icon: "message-plus")
    ui_action(:update, intent: :secondary, label_key: "comment.action.update", icon: "pencil")
    ui_action(:destroy, intent: :destructive, label_key: "comment.action.destroy", icon: "trash")

    ui_attribute(:body, label_key: "comment.body", order: 1, widget: :textarea)
    ui_attribute(:posted_at, label_key: "comment.posted_at", order: 2)
  end
end
