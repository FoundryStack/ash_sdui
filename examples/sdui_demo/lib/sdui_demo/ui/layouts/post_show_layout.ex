defmodule SduiDemo.UI.Layouts.PostShowLayout do
  @moduledoc """
  Builds a per-post SDUI layout for the PostShowLive page.

  Unlike BlogLayout (which uses ordinal "first"), this builder takes a specific
  post_id and author_id so the layout resolves deterministically to the right
  records — essential for production pages at /posts/:id.

  Layout tree:
    PostCard@v1 (root — post by ID)
    ├── :author  → UserCard@v1  (post author by ID)
    └── :comments → CommentItem@v1 × N (all comments for this post)
  """

  alias AshSDUI.Layout

  @doc """
  Builds and registers an ephemeral layout for a specific post.
  Returns the layout name so the caller can load it with Renderer.to_tree/1.

  The layout name is unique per post: "post-show-<id>".
  """
  def build_and_register(post, comments) do
    layout_name = "post-show-#{post.id}"

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

    post_card = %Layout.Node{
      id: "post-show-card-#{post.id}",
      component: "PostCard@v1",
      bind_subject: :post,
      region: :default,
      order: 0,
      subject_resource: "SduiDemo.Blog.Post",
      subject_id: to_string(post.id),
      children: [author_node | comment_nodes]
    }

    Layout.register(layout_name, %Layout.LayoutDef{
      name: layout_name,
      root: post_card
    })

    layout_name
  end
end
