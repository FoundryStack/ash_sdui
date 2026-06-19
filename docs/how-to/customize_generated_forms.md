# How to Customize Generated Forms

Use this guide when a generated form should stay on `AshSDUI.LiveResource`, but
you need more control over field widgets, visibility, custom field rendering, or
save payload shaping.

For the public API behind this guide, see
[Public API Map](../reference/public_api.md).

## Drive form fields from metadata

Generated forms should come from shared metadata instead of hand-maintained
field lists.

```elixir
sdui do
  view :new, recipe: :form, action: :create
  view :edit, recipe: :form, action: :update

  ui_field :title, label: "Headline", widget: :text_input
  ui_field :body, label: "Body", widget: :textarea
  ui_field :email, label: "Editor Email", widget: :email
end
```

`AshSDUI.Form.fields/2` combines UI metadata with the Ash action's accepted
attributes.

## Choose a non-default input with `widget:`

Use `widget:` when a generated form should render something other than the
default text input.

Supported examples in the current package include:

- `:text_input`
- `:textarea`
- `:email`
- `:checkbox`
- `:datetime`
- `:select`
- `:multiselect`

This is the preferred way to select `textarea`, `email`, and other field types
for generated forms.

## Render an existing related record as a generated select

For `belongs_to` fields, keep the metadata small and let the form infer the
relationship from the source attribute.

```elixir
relationships do
  belongs_to :author, MyApp.Accounts.User do
    source_attribute :author_id
    define_attribute? false
  end
end

sdui do
  ui_field :author_id, label: "Author"
end
```

When the action accepts `:author_id`, the generated form renders a select and
loads options from `MyApp.Accounts.User`.

## Render `has_one`, `has_many`, and `many_to_many` selectors

For relationship arguments, declare the action argument, manage the
relationship, and point the UI field at the relationship name.

```elixir
update :update do
  accept [:title]
  argument :cover_id, :uuid
  argument :tag_ids, {:array, :uuid}, allow_nil?: true

  change manage_relationship(:cover_id, :cover, type: :append_and_remove)
  change manage_relationship(:tag_ids, :tags, type: :append_and_remove)
end

sdui do
  ui_field :cover_id, label: "Cover", relationship: :cover, option_label: :title
  ui_field :tag_ids, label: "Tags", relationship: :tags, option_label: :name
end
```

The generated form uses these defaults:

- `belongs_to` and `has_one` render as `:select`
- `has_many` and `many_to_many` render as `:multiselect`
- option values default to the related resource primary key
- option labels default to `:name`, `:title`, `:label`, `:username`, or `:email`

## Override labels, prompts, and read actions for generated selectors

Use selector metadata when the defaults are not enough.

```elixir
ui_field :assignee_id,
  label: "Assignee",
  relationship: :assignee,
  option_label: :full_name,
  prompt: "Choose a teammate",
  read_action: :list_assignable_users
```

This keeps the generated form path while changing how options are loaded and
presented.

## Hide fields without changing the action contract

Use `hidden: true` or `form?: false` when an action accepts a field that should
not be shown in the generated form.

```elixir
ui_field :avatar_url, label: "Avatar", hidden: true
ui_field :published_at, label: "Published", form?: false
```

This keeps the resource contract intact while narrowing the generated form
surface.

## Use a custom field component for one field

Set `field_component:` when one field needs special presentation without
replacing the whole form path.

```elixir
ui_field :body,
  label: "Body",
  widget: :textarea,
  field_component: MyAppWeb.Components.PostPublishHintField
```

This is a good fit for inline hints, composite controls, or field-specific UI
behavior.

## Render a shared generated form component

If your app uses a shared wrapper component, keep it built on
`AshSDUI.Form.fields/2` instead of duplicating field lists.

```elixir
defmodule MyAppWeb.Components.ResourceForm do
  use Phoenix.Component

  attr :form, :any, required: true
  attr :resource, :atom, required: true
  attr :action, :atom, required: true

  def render(assigns) do
    assigns =
      assigns
      |> assign(:ui, assigns.resource)
      |> assign_new(:fields, fn -> AshSDUI.Form.fields(assigns.resource, assigns.action) end)

    AshSDUI.Components.RecordForm.render(assigns)
  end
end
```

This keeps the app-specific wrapper thin while leaving field selection to shared
metadata.

## Add derived values before save

Use `ash_sdui_transform_form_params/3` when the form should submit more than the
visible fields.

```elixir
def ash_sdui_transform_form_params(:new, params, socket) do
  %{
    "title" => Map.get(params, "title", ""),
    "body" => Map.get(params, "body", "")
  }
  |> Map.put("author_id", to_string(socket.assigns.demo_user.id))
end
```

Use this for values such as:

- `author_id`
- derived timestamps
- hidden control params like publish toggles

Generated multiselects already normalize missing keys to empty lists so update
forms can clear all selected related records.

## Keep action acceptance aligned

If a field should participate in the generated form, make sure the underlying
Ash action accepts it. Generated forms reflect both UI metadata and action
contracts, not UI metadata alone.
