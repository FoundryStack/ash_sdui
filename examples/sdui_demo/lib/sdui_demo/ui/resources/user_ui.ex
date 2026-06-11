defmodule SduiDemo.UI.Resources.UserUI do
  @moduledoc """
  SDUI UI metadata for the User domain resource.

  Separates UI concerns from domain logic — `SduiDemo.Accounts.User` remains
  a pure Ash resource while this module owns all SDUI annotations.
  """

  use AshSDUI.Resource.Standalone

  sdui do
    for_resource SduiDemo.Accounts.User
    default_component "UserCard@v1"

    ui_action :create, intent: :primary, label: "Create User", icon: "user-plus"
    ui_action :read, intent: :secondary, label: "View", icon: "eye"
    ui_action :update, intent: :secondary, label: "Edit", icon: "pencil"
    ui_action :destroy, intent: :destructive, label: "Delete", icon: "trash"

    ui_attribute :username, label: "Username", order: 1
    ui_attribute :email, label: "Email Address", order: 2
    ui_attribute :avatar_url, label: "Avatar URL", order: 3, hidden: true
  end
end
