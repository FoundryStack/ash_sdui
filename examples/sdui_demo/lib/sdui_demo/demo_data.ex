defmodule SduiDemo.DemoData do
  @moduledoc false

  alias SduiDemo.Accounts.User
  alias SduiDemo.Blog.Post
  alias SduiDemo.Blog.Comment

  @demo_user_attrs %{
    username: "demo_user",
    email: "demo@example.com",
    avatar_url: "https://api.example.com/avatars/demo.jpg"
  }

  def bootstrap do
    with {:ok, _status, user} <- ensure_demo_user(),
         {:ok, _status, post} <- ensure_demo_post(user),
         :ok <- ensure_demo_comments(user, post) do
      :ok
    else
      {:error, _reason} -> :ok
    end
  end

  def ensure_demo_user do
    case Ash.read(User) do
      {:ok, []} ->
        User
        |> Ash.Changeset.for_create(:create, @demo_user_attrs)
        |> Ash.create()
        |> case do
          {:ok, user} -> {:ok, :created, user}
          {:error, reason} -> {:error, reason}
        end

      {:ok, [user | _]} ->
        {:ok, :existing, user}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def ensure_demo_post(user) do
    case Ash.read(Post) do
      {:ok, []} ->
        Post
        |> Ash.Changeset.for_create(:create, %{
          title: "Introducing Ash SDUI",
          body: """
          Server-Driven UI lets you change your interface without deploying new code. \
          This post is rendered by a multi-resource SDUI layout: \
          the author card, post body, and comments below are each independent components \
          resolved from separate Ash resources at render time.\
          """,
          author_id: user.id,
          published_at: DateTime.utc_now()
        })
        |> Ash.create()
        |> case do
          {:ok, post} -> {:ok, :created, post}
          {:error, reason} -> {:error, reason}
        end

      {:ok, [post | _]} ->
        {:ok, :existing, post}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def ensure_demo_comments(user, post) do
    case Ash.read(Comment) do
      {:ok, []} ->
        comments = [
          %{
            body: "Great introduction! The tree-based rendering model is clever.",
            post_id: post.id,
            author_id: user.id,
            posted_at: DateTime.utc_now()
          },
          %{
            body: "Love how label_key separates translations from resource annotations.",
            post_id: post.id,
            author_id: user.id,
            posted_at: DateTime.utc_now()
          }
        ]

        Enum.each(comments, fn attrs ->
          Comment
          |> Ash.Changeset.for_create(:create, attrs)
          |> Ash.create()
        end)

        :ok

      {:ok, _existing} ->
        :ok

      {:error, _reason} ->
        :ok
    end
  end

  def demo_user_attrs, do: @demo_user_attrs
end
