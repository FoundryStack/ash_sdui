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
  alias AshSDUI.Layout.Builder

  def register do
    root =
      Builder.node("Layouts.TwoColumnLayout@v1",
        id: "blog-root",
        children: [
          Builder.resource(SduiDemo.UI.Resources.UserUI,
            id: "blog-sidebar-author",
            region: :sidebar
          ),
          Builder.resource(SduiDemo.UI.Resources.PostUI,
            id: "blog-post-card",
            region: :main,
            children: [
              Builder.resource(SduiDemo.UI.Resources.UserUI,
                id: "blog-post-author",
                region: :author
              ),
              Builder.resource(SduiDemo.UI.Resources.CommentUI,
                id: "blog-comment-1",
                region: :comments,
                order: 0
              ),
              Builder.resource(SduiDemo.UI.Resources.CommentUI,
                id: "blog-comment-2",
                region: :comments,
                order: 1,
                subject_id: "second"
              )
            ]
          )
        ]
      )

    Layout.register("blog-post", %Layout.LayoutDef{
      name: "blog-post",
      root: root
    })
  end
end
