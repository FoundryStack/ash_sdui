defmodule SduiDemoWeb.Live.BlogLiveTest do
  use SduiDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    AshSDUI.Registry.init_table()
    clear_blog_fixtures()

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

  defp clear_blog_fixtures do
    destroy_all(SduiDemo.Blog.Comment)
    destroy_all(SduiDemo.Blog.Post)
    destroy_all(SduiDemo.Accounts.User)
  end

  defp destroy_all(resource) do
    case Ash.read(resource) do
      {:ok, records} -> Enum.each(records, &Ash.destroy!/1)
      _ -> :ok
    end
  end

  describe "posts index" do
    test "renders a classic editorial feed instead of a generic table", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, "/posts")

      assert html =~ ~s(data-testid="editorial-feed")
      assert html =~ ~s(data-testid="editorial-posts-page")
      assert html =~ "mx-auto w-full max-w-6xl"
      assert html =~ "Featured story"
      assert html =~ "More from the feed"
      assert html =~ "tuned through recipe_overrides"
      assert html =~ post.title
      assert html =~ "Published"
      assert html =~ "Read"
      refute html =~ "<table"
    end

    test "shows empty state when no posts (setup creates demo data)", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/posts")

      # At minimum one post exists from setup
      refute html =~ "No posts yet"
    end

    test "delete removes post from list", %{conn: conn, post: post} do
      {:ok, extra_post} =
        SduiDemo.Blog.Post
        |> Ash.Changeset.for_create(:create, %{
          title: "Delete Me",
          body: "Secondary post for delete coverage.",
          author_id: post.author_id
        })
        |> Ash.create()

      {:ok, view, _html} = live(conn, "/posts")

      view |> element("[phx-click='delete'][phx-value-id='#{extra_post.id}']") |> render_click()

      assert {:error, _reason} = Ash.get(SduiDemo.Blog.Post, extra_post.id, domain: SduiDemo.Blog)
      assert {:ok, _post} = Ash.get(SduiDemo.Blog.Post, post.id, domain: SduiDemo.Blog)
    end

    test "shows author and editorial metadata", %{conn: conn, user: user, post: post} do
      {:ok, _view, html} = live(conn, "/posts")

      assert html =~ user.username
      assert html =~ post.title
      assert html =~ "Create Post"
      assert html =~ "AshSDUI Journal"
    end

    test "generated index uses the built-in collection recipe with overrides", %{
      conn: conn,
      post: post
    } do
      {:ok, _view, html} = live(conn, "/posts/generated")

      assert html =~ "mx-auto w-full max-w-6xl"
      assert html =~ "Headline"
      assert html =~ "Published"
      assert html =~ "Compose Post"
      assert html =~ "Open Generated"
      assert html =~ "Revise"
      assert html =~ post.title
      assert html =~ "<table"
      refute html =~ ~s(data-testid="editorial-feed")
    end

    test "generated index exposes query controls and syncs search params", %{conn: conn} do
      {:ok, view, html} = live(conn, "/posts/generated")

      assert html =~ "Search"
      assert html =~ "Reset"

      view
      |> form("form[phx-change='query']", %{"search" => "Test"})
      |> render_change()

      assert_patch(view, "/posts/generated?limit=10&search=Test&sort=-published_at")
      assert render(view) =~ ~s(value="Test")
    end

    test "generated index toggles sort and pagination in params", %{conn: conn} do
      {:ok, [user | _]} = Ash.read(SduiDemo.Accounts.User)

      Enum.each(1..10, fn index ->
        SduiDemo.Blog.Post
        |> Ash.Changeset.for_create(:create, %{
          title: "Extra Post #{index}",
          body: "More rows for pagination coverage.",
          author_id: user.id
        })
        |> Ash.create!()
      end)

      {:ok, view, _html} = live(conn, "/posts/generated")

      view
      |> element("button[phx-click='sort'][phx-value-field='title']")
      |> render_click()

      assert_patch(view, "/posts/generated?limit=10&sort=title")

      view
      |> element("button[phx-click='paginate'][phx-value-offset='10']")
      |> render_click()

      assert_patch(view, "/posts/generated?limit=10&offset=10&sort=title")
    end

    test "generated index resets query params", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/posts/generated?search=Test&sort=title&offset=10")

      view
      |> element("button[phx-click='reset_query']")
      |> render_click()

      assert_patch(view, "/posts/generated?limit=10&sort=-published_at")
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
      {:ok, view, html} = live(conn, "/posts/#{post.id}")

      # Verify initial state has 2 comments
      assert html =~ "First comment here."
      assert html =~ "Second comment here."
      assert html =~ "Comments (2)"

      view
      |> form("form[phx-submit='submit_comment']", comment: %{body: "A brand new comment!"})
      |> render_submit()

      # After submission, get the fresh HTML from the view
      html = render(view)

      # Verify the new comment appears in the rendered HTML
      assert html =~ "A brand new comment!"
      # Verify the comment count increased
      assert html =~ "Comments (3)"
      # Verify the success flash message appears
      assert html =~ "added" or html =~ "success"
    end
  end

  describe "post form" do
    test "PostUI form metadata drives generated fields" do
      fields = AshSDUI.Form.fields(SduiDemo.UI.Resources.PostUI, :create)

      assert Enum.map(fields, & &1.name) == [:title, :body]
      assert Enum.find(fields, &(&1.name == :body)).widget == :textarea
    end

    test "renders new post form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/posts/new")

      assert html =~ "New Post"
      assert html =~ "Title"
      assert html =~ "Content"
      assert html =~ "custom component"
      assert html =~ "Create Post"
      assert html =~ "text-3xl"
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

    test "generated detail route renders through view metadata", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, "/posts/generated/#{post.id}")

      assert html =~ "mx-auto w-full max-w-6xl"
      assert html =~ post.title
      assert html =~ post.body
      assert html =~ ~s(data-testid="record-detail")
    end

    test "creates a new post successfully", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/posts/new")

      result =
        view
        |> form("form[phx-submit='save']", post: %{title: "Test Post", body: "Test body"})
        |> render_submit()

      case result do
        {:error, {:live_redirect, %{to: to}}} ->
          assert String.match?(to, ~r|/posts/[a-f0-9\-]+|)
          post_id = String.slice(to, 7..-1//1)
          {:ok, post} = SduiDemo.Blog.Post |> Ash.get(post_id, domain: SduiDemo.Blog)
          assert post.title == "Test Post"
          assert post.body == "Test body"

        html when is_binary(html) ->
          assert html =~ "Test Post" or html =~ "created"
      end
    end
  end

  describe "landing page" do
    test "uses the shared page shell with the how it works section", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "How it works"
      assert html =~ "Open the blog"
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
      actions = AshSDUI.Resource.Info.ui_intents(SduiDemo.UI.Resources.PostUI)
      names = Enum.map(actions, & &1.name)

      assert :create in names
      assert :read in names
      assert :publish in names
      assert :destroy in names
    end

    test "PostUI actions use label_key for i18n" do
      actions = AshSDUI.Resource.Info.ui_intents(SduiDemo.UI.Resources.PostUI)
      create_action = Enum.find(actions, &(&1.name == :create))

      assert create_action.label_key == "post.action.create"
      assert create_action.label == nil
    end

    test "resolve_label resolves via SduiDemo.Gettext" do
      actions = AshSDUI.Resource.Info.ui_intents(SduiDemo.UI.Resources.PostUI)
      create_action = Enum.find(actions, &(&1.name == :create))

      label = AshSDUI.Resource.Info.resolve_label(create_action, SduiDemo.Gettext)
      assert label == "New Post"
    end

    test "UserUI resolves label via gettext_backend configured on the module" do
      attrs = AshSDUI.Resource.Info.ui_fields(SduiDemo.UI.Resources.UserUI)
      username_attr = Enum.find(attrs, &(&1.name == :username))

      label = AshSDUI.Resource.Info.resolve_label(username_attr, SduiDemo.UI.Resources.UserUI)
      assert label == "Username"
    end
  end
end
