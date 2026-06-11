defmodule SduiDemo.UI.Resources.UserUI do
  @moduledoc """
  SDUI UI metadata for the User domain resource.

  Separates UI concerns from domain logic — `SduiDemo.Accounts.User` remains
  a pure Ash resource while this module owns all SDUI annotations.

  Labels use gettext keys resolved via `SduiDemo.Gettext` at runtime,
  so translations live in `priv/gettext/*/sdui.po` rather than in code.
  """

  use AshSDUI.Resource.Standalone

  sdui do
    for_resource SduiDemo.Accounts.User
    default_component "UserCard@v1"
    gettext_backend SduiDemo.Gettext

    ui_action :create, intent: :primary, label_key: "user.action.create", icon: "user-plus"
    ui_action :read, intent: :secondary, label: "View", icon: "eye"
    ui_action :update, intent: :secondary, label_key: "user.action.update", icon: "pencil"
    ui_action :destroy, intent: :destructive, label_key: "user.action.destroy", icon: "trash"

    ui_attribute :username, label_key: "user.username", order: 1
    ui_attribute :email, label_key: "user.email", order: 2
    ui_attribute :avatar_url, label_key: "user.avatar_url", order: 3, hidden: true
  end
end
