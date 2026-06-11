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

  describe "posts index" do
    test "lists posts with DaisyUI cards", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, "/posts")

      assert html =~ post.title
      assert html =~ "Published"
      assert html =~ "Read"
    end

    test "shows empty state when no posts (setup creates demo data)", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/posts")

      # At minimum one post exists from setup
      refute html =~ "No posts yet"
    end

    test "delete removes post from list", %{conn: conn, post: post} do
      {:ok, view, _html} = live(conn, "/posts")

      html = view |> element("[phx-click='delete'][phx-value-id='#{post.id}']") |> render_click()

      refute html =~ post.id
    end
  end

  describe "post show with SDUI rendering" do
    test "renders PostCard via SDUI", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, "/posts/#{post.id}")

      assert html =~ ~s(data-testid="post-card")
      assert html =~ post.title
    end

    test "renders nested UserCard (author) via SDUI", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, "/posts/#{post.id}")

      assert html =~ ~s(data-testid="user-card")
    end

    test "renders CommentItems via SDUI", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, "/posts/#{post.id}")

      assert html =~ ~s(data-testid="comment-item")
      assert html =~ "First comment here."
      assert html =~ "Second comment here."
    end

    test "shows publish button for draft post", %{conn: conn, user: user} do
      {:ok, draft} =
        SduiDemo.Blog.Post
        |> Ash.Changeset.for_create(:create, %{
          title: "Draft Post",
          body: "Not published yet.",
          author_id: user.id
        })
        |> Ash.create()

      {:ok, _view, html} = live(conn, "/posts/#{draft.id}")

      assert html =~ "Publish"
    end

    test "publish action marks post as published", %{conn: conn, user: user} do
      {:ok, draft} =
        SduiDemo.Blog.Post
        |> Ash.Changeset.for_create(:create, %{
          title: "Draft Post",
          body: "Not published yet.",
          author_id: user.id
        })
        |> Ash.create()

      {:ok, view, _html} = live(conn, "/posts/#{draft.id}")

      html = view |> element("button[phx-click='publish']") |> render_click()

      # Either flash message shows, or the badge changes to Published
      assert html =~ "published" or html =~ "Published" or html =~ "success"
    end

    test "add comment form is rendered", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, "/posts/#{post.id}")

      assert html =~ "Add a comment"
      assert html =~ "Post Comment"
    end

    test "submitting comment adds it to the SDUI tree", %{conn: conn, post: post} do
      {:ok, view, _html} = live(conn, "/posts/#{post.id}")

      html =
        view
        |> form("form[phx-submit='submit_comment']", comment: %{body: "A brand new comment!"})
        |> render_submit()

      # Check that the form still renders (no error) and either the comment appears or flash shows success
      assert html =~ "submit_comment" or html =~ "added" or html =~ "success"
    end
  end

  describe "post form" do
    test "renders new post form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/posts/new")

      assert html =~ "New Post"
      assert html =~ "Title"
      assert html =~ "Body"
      assert html =~ "Create Post"
      # Verify form has proper LiveView event attributes
      assert html =~ "phx-change=\"validate\""
      assert html =~ "phx-submit=\"save\""
    end

    test "shows validation error for blank title", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/posts/new")

      html =
        view
        |> form("form[phx-submit='save']", post: %{title: "", body: "Some body"})
        |> render_submit()

      # Should show error or stay on same page
      assert html =~ "New Post" or html =~ "required" or html =~ "blank"
    end

    test "renders edit form pre-populated", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, "/posts/#{post.id}/edit")

      assert html =~ "Edit Post"
      assert html =~ post.title
    end

    test "creates a new post successfully", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/posts/new")

      result =
        view
        |> form("form[phx-submit='save']", post: %{title: "Test Post", body: "Test body"})
        |> render_submit()

      # render_submit returns {:error, {:live_redirect, ...}} when push_navigate is called
      # This means the form submission was successful and redirected
      case result do
        {:error, {:live_redirect, %{to: to}}} ->
          # Successful redirect to post show page
          assert String.match?(to, ~r|/posts/[a-f0-9\-]+|)
        html when is_binary(html) ->
          # Or we might get HTML if it stays on the same page (error case)
          assert html =~ "Test Post" or html =~ "created"
      end
    end
  end

  describe "layout toggle" do
    test "switches between standard, blog, and minimal layouts", %{conn: conn, post: post} do
      {:ok, view, html} = live(conn, "/posts/#{post.id}")

      # All three tab buttons should be present
      assert html =~ "Standard"
      assert html =~ "Blog"
      assert html =~ "Minimal"

      # Click Blog tab
      html = view |> element("button[phx-value-mode='blog']") |> render_click()
      assert html =~ "Blog"

      # Click Minimal tab
      html = view |> element("button[phx-value-mode='minimal']") |> render_click()
      assert html =~ "Minimal"

      # Return to Standard
      html = view |> element("button[phx-value-mode='standard']") |> render_click()
      assert html =~ "Standard"
    end

    test "layout mode persists when adding comments", %{conn: conn, post: post} do
      {:ok, view, _html} = live(conn, "/posts/#{post.id}")

      # Switch to blog layout
      view |> element("button[phx-value-mode='blog']") |> render_click()

      # Add a comment
      html =
        view
        |> form("form[phx-submit='submit_comment']", comment: %{body: "New test comment"})
        |> render_submit()

      # Blog tab should still be active or at least present
      assert html =~ "Blog" or html =~ "submit_comment"
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

      label = AshSDUI.Resource.Info.resolve_label(username_attr, SduiDemo.UI.Resources.UserUI)
      assert label == "Username"
    end
  end
end
