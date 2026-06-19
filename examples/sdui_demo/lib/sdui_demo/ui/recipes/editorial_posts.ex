defmodule SduiDemo.UI.Recipes.EditorialPosts do
  @behaviour AshSDUI.LayoutRecipe

  alias AshSDUI.Layout.Builder
  alias AshSDUI.View
  alias SduiDemo.Accounts
  alias SduiDemo.Accounts.User

  @impl true
  def to_layout(%View{} = view, opts) do
    records = Keyword.get(opts, :records, [])
    {featured, remaining} = split_records(records)
    recipe_props = recipe_props(view)

    Builder.node("EditorialPostsPage@v1",
      id: "editorial-posts-page",
      static_props:
        %{
          title: view.assigns[:title] || "AshSDUI Journal",
          empty_title: view.assigns[:empty_state] || "No posts yet",
          empty_body:
            view.assigns[:empty_state_body] ||
              "Create your first entry to see the editorial recipe in action.",
          subtitle:
            "A generated index shaped by an app-side recipe, with room for custom layout and copy.",
          create_label: "Create Post",
          featured: serialize_post(featured),
          posts: Enum.map(remaining, &serialize_post/1)
        }
        |> Map.merge(recipe_props)
    )
  end

  defp recipe_props(view) do
    view.assigns
    |> Map.get(:recipe_overrides, %{})
    |> Map.get(:view, %{})
    |> Map.get(:props, %{})
  end

  defp split_records(records) do
    sorted =
      Enum.sort_by(
        records,
        fn record ->
          {not is_nil(record.published_at), published_rank(record.published_at)}
        end,
        :desc
      )

    case sorted do
      [featured | rest] -> {featured, rest}
      [] -> {nil, []}
    end
  end

  defp serialize_post(nil), do: nil

  defp serialize_post(post) do
    %{
      id: post.id,
      title: post.title,
      body: post.body,
      excerpt: excerpt(post.body),
      published_at: post.published_at,
      author_name: author_name(post),
      status: if(post.published_at, do: "Published", else: "Draft"),
      read_path: "/posts/#{post.id}",
      edit_path: "/posts/#{post.id}/edit"
    }
  end

  defp excerpt(nil), do: nil

  defp excerpt(body) do
    body
    |> String.trim()
    |> String.slice(0, 180)
    |> then(fn
      nil -> nil
      text when byte_size(body) > byte_size(text) -> text <> "..."
      text -> text
    end)
  end

  defp published_rank(nil), do: 0
  defp published_rank(date), do: DateTime.to_unix(date)

  defp load_author(nil), do: nil

  defp load_author(author_id) do
    case Ash.get(User, author_id, domain: Accounts) do
      {:ok, author} -> author
      _ -> nil
    end
  end

  defp author_name(post) do
    case Map.get(post, :author) do
      %{username: username} when is_binary(username) ->
        username

      %Ash.NotLoaded{} ->
        post.author_id
        |> load_author()
        |> case do
          %{username: username} -> username
          _ -> nil
        end

      nil ->
        post.author_id
        |> load_author()
        |> case do
          %{username: username} -> username
          _ -> nil
        end

      _ ->
        nil
    end
  end
end
