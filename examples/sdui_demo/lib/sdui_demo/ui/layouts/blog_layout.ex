defmodule SduiDemo.UI.Layouts.BlogLayout do
  @moduledoc """
  Blog layout: demonstrates multi-resource nesting in SDUI.

  Tree structure:
    Layouts.TwoColumnLayout@v1 (root)
    ├── :sidebar → UserCard@v1 (author — bound to User via "first")
    └── :main → PostCard@v1 (post — bound to Post via "first")
                └── :author  → UserCard@v1  (post author inline)
                └── :comments → CommentItem@v1 × N (each comment)

  The layout tree is static (code-defined). Subject resolution happens at
  render time via AshSDUI.Calculations.ResolveSubject: "first" loads the
  first available record from ETS.
  """

  alias AshSDUI.Layout

  def register do
    # Author card shown in sidebar
    sidebar_author = %Layout.Node{
      id: "blog-sidebar-author",
      component: "UserCard@v1",
      bind_subject: :user,
      region: :sidebar,
      order: 0,
      subject_resource: "SduiDemo.Accounts.User",
      subject_id: "first",
      children: []
    }

    # Author card embedded inside the post (shows who wrote it)
    post_author = %Layout.Node{
      id: "blog-post-author",
      component: "UserCard@v1",
      bind_subject: :user,
      region: :author,
      order: 0,
      subject_resource: "SduiDemo.Accounts.User",
      subject_id: "first",
      children: []
    }

    # Individual comment items — we embed two demo comment slots
    comment_1 = %Layout.Node{
      id: "blog-comment-1",
      component: "CommentItem@v1",
      bind_subject: nil,
      region: :comments,
      order: 0,
      subject_resource: "SduiDemo.Blog.Comment",
      subject_id: "first",
      children: []
    }

    comment_2 = %Layout.Node{
      id: "blog-comment-2",
      component: "CommentItem@v1",
      bind_subject: nil,
      region: :comments,
      order: 1,
      subject_resource: "SduiDemo.Blog.Comment",
      subject_id: "second",
      children: []
    }

    # Post card in main area, with nested author + comments
    post_card = %Layout.Node{
      id: "blog-post-card",
      component: "PostCard@v1",
      bind_subject: :post,
      region: :main,
      order: 0,
      subject_resource: "SduiDemo.Blog.Post",
      subject_id: "first",
      children: [post_author, comment_1, comment_2]
    }

    root = %Layout.Node{
      id: "blog-root",
      component: "Layouts.TwoColumnLayout@v1",
      bind_subject: nil,
      region: :default,
      order: 0,
      children: [sidebar_author, post_card]
    }

    Layout.register("blog-post", %Layout.LayoutDef{
      name: "blog-post",
      root: root
    })
  end
end
