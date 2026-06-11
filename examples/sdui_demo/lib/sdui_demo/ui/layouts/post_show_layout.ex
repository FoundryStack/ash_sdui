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

  alias AshSDUI.Layout

  @doc """
  Builds and registers an ephemeral layout for a specific post.

  Options:
  - `:mode` — :standard | :blog | :minimal (default :standard)

  Returns the layout name: "post-show-standard-<id>", etc.
  """
  def build_and_register(post, comments, opts \\ []) do
    mode = Keyword.get(opts, :mode, :standard)
    layout_name = "post-show-#{mode}-#{post.id}"

    root =
      case mode do
        :standard -> standard_root(post, comments)
        :blog -> blog_root(post, comments)
        :minimal -> minimal_root(post)
      end

    Layout.register(layout_name, %Layout.LayoutDef{
      name: layout_name,
      root: root
    })

    # Invalidate the renderer cache so the new layout is used
    AshSDUI.Cache.evict(layout_name)

    layout_name
  end

  defp standard_root(post, comments) do
    author_node = %Layout.Node{
      id: "post-show-author-#{post.id}",
      component: "UserCard@v1",
      bind_subject: :user,
      region: :author,
      order: 0,
      subject_resource: "SduiDemo.Accounts.User",
      subject_id: to_string(post.author_id),
      children: []
    }

    comment_nodes =
      comments
      |> Enum.sort_by(& &1.posted_at)
      |> Enum.with_index()
      |> Enum.map(fn {comment, index} ->
        %Layout.Node{
          id: "post-show-comment-#{comment.id}",
          component: "CommentItem@v1",
          bind_subject: nil,
          region: :comments,
          order: index,
          subject_resource: "SduiDemo.Blog.Comment",
          subject_id: to_string(comment.id),
          children: []
        }
      end)

    %Layout.Node{
      id: "post-show-card-#{post.id}",
      component: "PostCard@v1",
      bind_subject: :post,
      region: :default,
      order: 0,
      subject_resource: "SduiDemo.Blog.Post",
      subject_id: to_string(post.id),
      children: [author_node | comment_nodes]
    }
  end

  defp blog_root(post, comments) do
    author_node = %Layout.Node{
      id: "post-blog-author-#{post.id}",
      component: "UserCard@v1",
      bind_subject: :user,
      region: :sidebar,
      order: 0,
      subject_resource: "SduiDemo.Accounts.User",
      subject_id: to_string(post.author_id),
      children: []
    }

    comment_nodes =
      comments
      |> Enum.sort_by(& &1.posted_at)
      |> Enum.with_index()
      |> Enum.map(fn {comment, index} ->
        %Layout.Node{
          id: "post-blog-comment-#{comment.id}",
          component: "CommentItem@v1",
          bind_subject: nil,
          region: :comments,
          order: index,
          subject_resource: "SduiDemo.Blog.Comment",
          subject_id: to_string(comment.id),
          children: []
        }
      end)

    post_card = %Layout.Node{
      id: "post-blog-card-#{post.id}",
      component: "PostCard@v1",
      bind_subject: :post,
      region: :main,
      order: 0,
      subject_resource: "SduiDemo.Blog.Post",
      subject_id: to_string(post.id),
      children: comment_nodes
    }

    %Layout.Node{
      id: "post-blog-layout-#{post.id}",
      component: "Layouts.TwoColumnLayout@v1",
      bind_subject: nil,
      region: :default,
      order: 0,
      children: [author_node, post_card]
    }
  end

  defp minimal_root(post) do
    %Layout.Node{
      id: "post-minimal-card-#{post.id}",
      component: "PostCard@v1",
      bind_subject: :post,
      region: :default,
      order: 0,
      subject_resource: "SduiDemo.Blog.Post",
      subject_id: to_string(post.id),
      children: []
    }
  end
end
