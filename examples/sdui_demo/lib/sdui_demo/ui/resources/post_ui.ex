defmodule SduiDemo.UI.Resources.PostUI do
  @moduledoc """
  SDUI UI metadata for the Post domain resource.

  Annotates how posts are displayed and what actions are available.
  The default component renders a post with its author card and comment list as children.
  """

  use AshSDUI.Resource.Standalone

  sdui do
    for_resource SduiDemo.Blog.Post
    default_component "PostCard@v1"
    gettext_backend SduiDemo.Gettext

    ui_action :create, intent: :primary, label_key: "post.action.create", icon: "file-plus"
    ui_action :update, intent: :secondary, label_key: "post.action.update", icon: "pencil"
    ui_action :publish, intent: :info, label_key: "post.action.publish", icon: "send"
    ui_action :destroy, intent: :destructive, label_key: "post.action.destroy", icon: "trash"

    ui_attribute :title, label_key: "post.title", order: 1
    ui_attribute :body, label_key: "post.body", order: 2
    ui_attribute :published_at, label_key: "post.published_at", order: 3
  end
end
