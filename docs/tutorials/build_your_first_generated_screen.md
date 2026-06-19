# Build Your First Generated Screen

This tutorial walks through one complete path for building a small posts flow
with AshSDUI. You will define an Ash resource, add UI metadata, mount generated
LiveViews, and make one light customization without leaving the generated path.

By the end, you will have:

- a generated post index at `/posts`
- a generated new-post form at `/posts/new`
- a form that uses `:textarea` for the body
- an author select that loads existing users automatically
- a create action labeled from metadata
- one small presentation override that keeps the screen generated

## 1. Define the author resource

Start with the related resource that will supply the generated select options.

```elixir
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    domain: MyApp.Accounts

  attributes do
    uuid_primary_key :id

    attribute :username, :string do
      allow_nil? false
    end
  end

  actions do
    defaults [:read]

    create :create do
      accept [:username]
    end
  end
end
```

The generated post form will read users through this resource's primary
`:read` action.

## 2. Define the post resource

Start with an Ash resource that has a create action and a relationship-aware
attribute set.

```elixir
defmodule MyApp.Blog.Post do
  use Ash.Resource,
    domain: MyApp.Blog

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
    end

    attribute :body, :string do
      allow_nil? false
    end

    attribute :author_id, :uuid
    attribute :published_at, :utc_datetime
  end

  relationships do
    belongs_to :author, MyApp.Accounts.User do
      source_attribute :author_id
    end
  end

  actions do
    defaults [:read]

    create :create do
      accept [:title, :body, :author_id, :published_at]
    end
  end
end
```

This keeps the domain resource responsible for data shape and action contracts.

## 3. Add the UI module

Create a standalone UI module that owns how posts are presented.

```elixir
defmodule MyApp.UI.PostUI do
  use AshSDUI.Resource.Standalone

  sdui do
    for_resource MyApp.Blog.Post
    default_component "PostCard@v1"

    view :index, recipe: :collection, read_action: :read, title: "Posts"
    view :new, recipe: :form, action: :create

    ui_intent :create,
      style: :primary,
      label: "Write post",
      target: {:navigate, "/posts/new"},
      placement: :toolbar

    ui_field :title,
      label: "Headline",
      order: 1,
      widget: :text_input,
      index?: true,
      form?: true

    ui_field :body,
      label: "Body",
      order: 2,
      widget: :textarea,
      index?: false,
      form?: true

    ui_field :author_id,
      label: "Author",
      order: 3,
      form?: true

    ui_field :published_at,
      label: "Published",
      order: 4,
      form?: false
  end
end
```

The generated form will use `ui_field` metadata through `AshSDUI.Form.fields/2`.
Because `author_id` matches the `belongs_to :author` source attribute, the
generated form will render a select and load user options automatically.

## 4. Mount the generated index

Create a LiveView for the generated collection screen.

```elixir
defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :index,
    domain: MyApp.Blog
end
```

This is the default starting point for a metadata-driven screen.

## 5. Mount the generated form

Create a second LiveView for the new-post form.

```elixir
defmodule MyAppWeb.PostNewLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :new,
    domain: MyApp.Blog
end
```

Because the `:create` action accepts `:title`, `:body`, `:author_id`, and
`:published_at`, the generated form stays aligned with the underlying Ash
contract while still rendering the author relationship as a select.

## 6. Seed one user

Create at least one user so the generated author select has something to show.

```elixir
Ash.create!(MyApp.Accounts.User, %{username: "editor"}, action: :create, domain: MyApp.Accounts)
```

## 7. Add one light customization

Use `ash_sdui_view_opts/4` when you need a small presentation change without
replacing the generated screen.

```elixir
defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :index,
    domain: MyApp.Blog

  def ash_sdui_view_opts(_mode, _params, _session, _socket) do
    [
      recipe_overrides: [
        title: "Editorial Posts",
        empty_state: [
          title: "No posts yet",
          body: "Create the first story to populate the feed."
        ],
        fields: %{title: %{label: "Headline"}},
        intents: %{create: %{label: "Compose Post"}}
      ]
    ]
  end
end
```

This keeps the screen generated while letting you adjust labels and copy.

## 8. Add the routes

Expose both screens from your router.

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  live "/posts", PostsLive
  live "/posts/new", PostNewLive
end
```

## 9. Check the result

Start your Phoenix server and visit:

1. `/posts`
2. `/posts/new`

You should now have:

- a generated collection screen mounted by `AshSDUI.LiveResource`
- a generated form that renders `:body` as a textarea
- a generated author select backed by existing `User` records
- a create action whose label comes from UI metadata
- a small presentation override applied without replacing the generated host

## What you learned

In this tutorial, the Ash resource owned the data contract, the UI module owned
labels, widgets, and relationship selectors, and `AshSDUI.LiveResource` owned
the LiveView plumbing. That is the core generated-screen path in AshSDUI.

## Next step

Continue with [How to Author Generated Screens](../how-to/author_generated_screens.md)
to add deeper customization hooks, generated form shaping, and `layout: :sdui`
recipes.
