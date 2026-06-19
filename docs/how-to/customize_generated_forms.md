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

## Filter or sort generated selector options

Use selector metadata when the related list should load through a narrower or
ordered query.

```elixir
ui_field :reviewer_id,
  label: "Reviewer",
  relationship: :reviewer,
  option_label: :full_name,
  option_filter: %{active: true},
  option_sort: [:full_name]
```

This keeps the generated selector on the Ash query path while changing which
records appear and in what order.

## Render nested relationship forms inline

Use `ui_nested_form` when the form should create or edit related records inline
instead of only selecting existing ones.

```elixir
update :update do
  accept [:title]
  argument :cover, :map
  argument :comments, {:array, :map}, allow_nil?: true

  change manage_relationship(:cover, :cover, type: :direct_control)
  change manage_relationship(:comments, :comments, type: :direct_control)
end

sdui do
  ui_field :title, label: "Title"
  ui_nested_form :cover, label: "Cover"
  ui_nested_form :comments, label: "Comments"
end
```

`ui_nested_form` is the preferred path for:

- `has_one` child forms such as a profile or cover
- `has_many` child forms such as comments or addresses
- `many_to_many` child forms when the action manages destination records inline

Keep existing-record picking on `ui_field`. Use `ui_nested_form` only when the
input payload is nested maps instead of scalar IDs.

## Let Ash infer nested create and update flows

When the action uses `manage_relationship`, generated nested forms follow
AshPhoenix auto-inference instead of a separate form schema.

```elixir
change manage_relationship(:comments, :comments, type: :direct_control)
```

With that shape, generated nested forms can:

- preload existing related rows on edit screens
- add new rows inline
- remove rows inline
- reorder list relationships

Keep the child resource metadata authoritative so generated nested rows know
which fields to render.

## Render many-to-many join details inline

When a `many_to_many` action manages join attributes, generated nested forms
render the destination row and the `_join` subform together.

```elixir
sdui do
  ui_nested_form :tags, label: "Tags"
end
```

If the join resource exposes `ui_field` metadata such as `:position`, the
generated nested form renders those fields under each related record row.

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
