defmodule SduiDemoWeb.Live.BlogLiveTest do
  use SduiDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    AshSDUI.Registry.init_table()

    {:ok, user} =
      SduiDemo.Accounts.User
      |> Ash.Changeset.for_create(:create, %{
        username: "blog_author",
        email: "author@example.com"
      })
      |> Ash.create()

    {:ok, post} =
      SduiDemo.Blog.Post
      |> Ash.Changeset.for_create(:create, %{
        title: "Test Post",
        body: "This is the post body.",
        author_id: user.id,
        published_at: DateTime.utc_now()
      })
      |> Ash.create()

    {:ok, _comment1} =
      SduiDemo.Blog.Comment
      |> Ash.Changeset.for_create(:create, %{
        body: "First comment here.",
        post_id: post.id,
        author_id: user.id,
        posted_at: DateTime.utc_now()
      })
      |> Ash.create()

    {:ok, _comment2} =
      SduiDemo.Blog.Comment
      |> Ash.Changeset.for_create(:create, %{
        body: "Second comment here.",
        post_id: post.id,
        author_id: user.id,
        posted_at: DateTime.utc_now()
      })
      |> Ash.create()

    {:ok, user: user, post: post}
  end

  describe "demo_live layout switching" do
    test "renders user-dashboard layout by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "two-column-layout"
      assert html =~ "user-dashboard"
    end

    test "switches to blog-post layout", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html = view |> element("button", "Blog Post (multi-resource)") |> render_click()

      assert html =~ "blog-post"
    end

    test "blog layout renders post card component", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html = view |> element("button", "Blog Post (multi-resource)") |> render_click()

      # Structural assertion — post-card component rendered, not caring about which post
      # (ETS may contain seeded posts; we just verify the component renders)
      assert html =~ ~s(data-testid="post-card")
      assert html =~ "post-card"
    end

    test "blog layout renders nested comment items", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html = view |> element("button", "Blog Post (multi-resource)") |> render_click()

      # Structural: comment-item components present (seeded or test data)
      assert html =~ ~s(data-testid="comment-item")
      assert html =~ "comment-item"
    end

    test "blog layout renders author user card in sidebar", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html = view |> element("button", "Blog Post (multi-resource)") |> render_click()

      # User card always present — the first user in ETS (either seeded or test user)
      assert html =~ ~s(data-testid="user-card")
    end
  end

  describe "UI annotation introspection" do
    test "PostUI for_resource resolves to Post" do
      assert AshSDUI.Resource.Info.for_resource(SduiDemo.UI.Resources.PostUI) ==
               SduiDemo.Blog.Post
    end

    test "CommentUI for_resource resolves to Comment" do
      assert AshSDUI.Resource.Info.for_resource(SduiDemo.UI.Resources.CommentUI) ==
               SduiDemo.Blog.Comment
    end

    test "PostUI has correct actions" do
      actions = AshSDUI.Resource.Info.ui_actions(SduiDemo.UI.Resources.PostUI)
      names = Enum.map(actions, & &1.name)

      assert :create in names
      assert :publish in names
      assert :destroy in names
    end

    test "PostUI actions use label_key for i18n" do
      actions = AshSDUI.Resource.Info.ui_actions(SduiDemo.UI.Resources.PostUI)
      create_action = Enum.find(actions, &(&1.name == :create))

      assert create_action.label_key == "post.action.create"
      assert create_action.label == nil
    end

    test "resolve_label resolves via SduiDemo.Gettext" do
      actions = AshSDUI.Resource.Info.ui_actions(SduiDemo.UI.Resources.PostUI)
      create_action = Enum.find(actions, &(&1.name == :create))

      label = AshSDUI.Resource.Info.resolve_label(create_action, SduiDemo.Gettext)
      assert label == "New Post"
    end

    test "UserUI resolves label via gettext_backend configured on the module" do
      attrs = AshSDUI.Resource.Info.ui_attributes(SduiDemo.UI.Resources.UserUI)
      username_attr = Enum.find(attrs, &(&1.name == :username))

      # Resolves using the backend configured in the sdui block
      label = AshSDUI.Resource.Info.resolve_label(username_attr, SduiDemo.UI.Resources.UserUI)
      assert label == "Username"
    end
  end
end
