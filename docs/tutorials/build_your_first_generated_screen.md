# Build Your First Generated Screen

This tutorial walks through one safe path for building a generated screen with
AshSDUI. You will define a small UI module, mount it with
`AshSDUI.LiveResource`, and add one form field widget and one action label from
metadata.

## 1. Add a UI module

Create a UI module for the Ash resource you want to render.

```elixir
defmodule MyApp.UI.PostUI do
  use AshSDUI.Resource,
    resource: MyApp.Blog.Post

  sdui do
    view :index, recipe: :collection, read_action: :read
    view :new, recipe: :form, action: :create

    ui_field :title, label: "Headline", widget: :text_input, order: 0
    ui_field :body, label: "Body", widget: :textarea, order: 1

    ui_intent :create,
      label: "Write post",
      target: {:navigate, "/posts/new"}
  end
end
```

Use `widget:` when a generated form should render something other than the
default text input.

## 2. Mount the generated screen

Create a LiveView that uses `AshSDUI.LiveResource`.

```elixir
defmodule MyAppWeb.PostsLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :index,
    domain: MyApp.Blog
end
```

This gives the screen a generated collection view from the UI metadata.

## 3. Mount the generated form

Create a second LiveView for the form view.

```elixir
defmodule MyAppWeb.PostNewLive do
  use AshSDUI.LiveResource,
    ui: MyApp.UI.PostUI,
    view: :new,
    domain: MyApp.Blog
end
```

The generated form uses `AshSDUI.Form.fields/2` and the `ui_field` metadata you
defined earlier.

## 4. Add the routes

Expose both generated screens from your router.

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  live "/posts", PostsLive
  live "/posts/new", PostNewLive
end
```

## 5. Check the result

Start your Phoenix server and visit:

1. `/posts`
2. `/posts/new`

You should now have:

- a generated collection screen mounted by `AshSDUI.LiveResource`
- a generated form screen using the `:textarea` widget for `:body`
- a create intent labeled `Write post`

## Next step

Continue with [Author Generated Screens](../how-to/author_generated_screens.md)
when you want to customize a generated screen without leaving the metadata-first
path.
