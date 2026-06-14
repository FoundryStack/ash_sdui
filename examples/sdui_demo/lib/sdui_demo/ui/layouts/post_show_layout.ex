defmodule SduiDemo.UI.Layouts.PostShowLayout do
  @moduledoc """
  Builds per-post SDUI layouts in three modes: standard, blog, minimal.

  Each mode has a unique layout structure optimized for different views,
  all deterministically bound to specific post/author/comment IDs.

  Modes:
  - :standard — PostCard (root) with nested author + comments (DEFAULT)
  - :blog — TwoColumnLayout with author sidebar + post main
  - :minimal — PostCard only, no children
  """

  alias AshSDUI.Layout.Builder

  @doc """
  Builds and registers an ephemeral layout for a specific post.

  Options:
  - `:mode` — :standard | :blog | :minimal (default :standard)

  Returns `{layout_name, root}` where the root can be passed straight to
  `AshSDUI.LiveScreen.assign_layout/3`.
  """
  def build(post, comments, opts \\ []) do
    mode = Keyword.get(opts, :mode, :standard)
    layout_name = "post-show-#{mode}-#{post.id}"

    root =
      case mode do
        :standard -> standard_root(post, comments)
        :blog -> blog_root(post, comments)
        :minimal -> minimal_root(post)
      end

    {layout_name, root}
  end

  def build_and_register(post, comments, opts \\ []) do
    {layout_name, root} = build(post, comments, opts)
    Builder.register(layout_name, root)
  end

  defp standard_root(post, comments) do
    Builder.resource(SduiDemo.UI.Resources.PostUI,
      id: "post-show-card-#{post.id}",
      subject_id: post.id,
      children: [
        Builder.resource(SduiDemo.UI.Resources.UserUI,
          id: "post-show-author-#{post.id}",
          region: :author,
          subject_id: post.author_id
        )
        | sorted_comment_nodes(comments, "post-show-comment")
      ]
    )
  end

  defp blog_root(post, comments) do
    Builder.node("Layouts.TwoColumnLayout@v1",
      id: "post-blog-layout-#{post.id}",
      children: [
        Builder.resource(SduiDemo.UI.Resources.UserUI,
          id: "post-blog-author-#{post.id}",
          region: :sidebar,
          subject_id: post.author_id
        ),
        Builder.resource(SduiDemo.UI.Resources.PostUI,
          id: "post-blog-card-#{post.id}",
          region: :main,
          subject_id: post.id,
          children: sorted_comment_nodes(comments, "post-blog-comment")
        )
      ]
    )
  end

  defp minimal_root(post) do
    Builder.resource(SduiDemo.UI.Resources.PostUI,
      id: "post-minimal-card-#{post.id}",
      subject_id: post.id
    )
  end

  defp sorted_comment_nodes(comments, prefix) do
    comments
    |> Enum.sort_by(& &1.posted_at)
    |> then(fn sorted_comments ->
      Builder.resources(SduiDemo.UI.Resources.CommentUI, sorted_comments,
        id_prefix: prefix,
        region: :comments
      )
    end)
  end
end
