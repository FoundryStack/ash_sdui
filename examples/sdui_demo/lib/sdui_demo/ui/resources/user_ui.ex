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
    for_resource(SduiDemo.Accounts.User)
    default_component("UserCard@v1")
    gettext_backend(SduiDemo.Gettext)

    view(:index, recipe: :collection, read_action: :read, title: "Users")
    view(:show, recipe: :detail, read_action: :read)

    ui_binding(:collection, source: {:resource, SduiDemo.Accounts.User}, many?: true)
    ui_binding(:record, source: {:resource, SduiDemo.Accounts.User}, many?: false)

    ui_intent(:create,
      style: :primary,
      label_key: "user.action.create",
      icon: "user-plus",
      target: {:navigate, "/users/new"}
    )

    ui_intent(:read,
      style: :secondary,
      label: "View",
      icon: "eye",
      target: {:navigate, "/users/:id"}
    )

    ui_intent(:update, style: :secondary, label_key: "user.action.update", icon: "pencil")
    ui_intent(:destroy, style: :destructive, label_key: "user.action.destroy", icon: "trash")

    ui_field(:username, label_key: "user.username", order: 1, widget: :text_input)
    ui_field(:email, label_key: "user.email", order: 2, widget: :email)
    ui_field(:avatar_url, label_key: "user.avatar_url", order: 3, hidden: true)
  end
end
