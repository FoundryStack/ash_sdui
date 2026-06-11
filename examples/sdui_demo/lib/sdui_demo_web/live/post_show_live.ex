defmodule SduiDemoWeb.Live.PostShowLive do
  use SduiDemoWeb, :live_view

  alias SduiDemo.Blog
  alias SduiDemo.Blog.{Post, Comment}
  alias SduiDemo.Accounts
  alias SduiDemo.Accounts.User
  alias SduiDemo.UI.Layouts.PostShowLayout

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case load_post(id) do
      {:ok, post, comments} ->
        layout_name = PostShowLayout.build_and_register(post, comments, mode: :standard)
        {:ok, tree} = AshSDUI.Renderer.to_tree(layout_name)
        demo_user = get_demo_user()

        comment_form =
          Comment
          |> AshPhoenix.Form.for_create(:create, domain: Blog, as: "comment")
          |> to_form()

        {:ok,
         socket
         |> assign(:post, post)
         |> assign(:comments, comments)
         |> assign(:__sdui_tree__, tree)
         |> assign(:comment_form, comment_form)
         |> assign(:demo_user, demo_user)
         |> assign(:layout_mode, :standard)
         |> assign(:page_title, post.title)}

      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, "Post not found.")
         |> push_navigate(to: "/posts")}
    end
  end

  @impl true
  def handle_event("switch_layout", %{"mode" => mode_str}, socket) do
    mode = String.to_atom(mode_str)
    post = socket.assigns.post
    comments = socket.assigns.comments
    layout_name = PostShowLayout.build_and_register(post, comments, mode: mode)
    {:ok, tree} = AshSDUI.Renderer.to_tree(layout_name)
    {:noreply, socket |> assign(:__sdui_tree__, tree) |> assign(:layout_mode, mode)}
  end

  @impl true
  def handle_event("validate_comment", %{"comment" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.comment_form.source, params)
    {:noreply, assign(socket, :comment_form, to_form(form))}
  end

  @impl true
  def handle_event("submit_comment", %{"comment" => params}, socket) do
    post = socket.assigns.post
    demo_user = socket.assigns.demo_user

    full_params =
      params
      |> Map.put("post_id", to_string(post.id))
      |> Map.put("posted_at", DateTime.to_iso8601(DateTime.utc_now()))
      |> maybe_put("author_id", demo_user && to_string(demo_user.id))

    case AshPhoenix.Form.submit(socket.assigns.comment_form.source, params: full_params) do
      {:ok, _comment} ->
        case load_post(to_string(post.id)) do
          {:ok, updated_post, comments} ->
            layout_name = PostShowLayout.build_and_register(updated_post, comments, mode: socket.assigns.layout_mode)
            {:ok, tree} = AshSDUI.Renderer.to_tree(layout_name)

            fresh_form =
              Comment
              |> AshPhoenix.Form.for_create(:create, domain: Blog, as: "comment")
              |> to_form()

            {:noreply,
             socket
             |> assign(:post, updated_post)
             |> assign(:comments, comments)
             |> assign(:__sdui_tree__, tree)
             |> assign(:comment_form, fresh_form)
             |> put_flash(:info, "Comment added!")}

          :not_found ->
            {:noreply, push_navigate(socket, to: "/posts")}
        end

      {:error, form} ->
        IO.inspect(form, label: "Form error")
        {:noreply, assign(socket, :comment_form, to_form(form))}
    end
  end

  @impl true
  def handle_event("publish", _params, socket) do
    post = socket.assigns.post

    case Ash.update(post, %{}, action: :publish, domain: Blog) do
      {:ok, updated_post} ->
        case load_post(to_string(updated_post.id)) do
          {:ok, post, comments} ->
            layout_name = PostShowLayout.build_and_register(post, comments, mode: socket.assigns.layout_mode)
            {:ok, tree} = AshSDUI.Renderer.to_tree(layout_name)

            {:noreply,
             socket
             |> assign(:post, post)
             |> assign(:__sdui_tree__, tree)
             |> put_flash(:info, "Post published!")}

          :not_found ->
            {:noreply, push_navigate(socket, to: "/posts")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not publish post.")}
    end
  end

  defp load_post(id) do
    case Ash.get(Post, id, domain: Blog) do
      {:ok, post} ->
        comments =
          case Ash.read(Comment, domain: Blog) do
            {:ok, all} -> Enum.filter(all, &(&1.post_id == post.id))
            _ -> []
          end

        {:ok, post, comments}

      {:error, _} ->
        :not_found
    end
  end

  defp get_demo_user do
    case Ash.read(User, domain: Accounts) do
      {:ok, [user | _]} -> user
      _ -> nil
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center gap-3 mb-6">
        <a href="/posts" class="btn btn-ghost btn-sm">← All Posts</a>
        <div class="flex-1" />
        <a href={"/posts/#{@post.id}/edit"} class="btn btn-outline btn-sm">Edit</a>
        <%= if !@post.published_at do %>
          <button phx-click="publish" class="btn btn-success btn-sm">Publish</button>
        <% end %>
      </div>

      <div class="tabs tabs-boxed mb-6">
        <button
          phx-click="switch_layout"
          phx-value-mode="standard"
          class={["tab", @layout_mode == :standard && "tab-active"]}
        >
          Standard
        </button>
        <button
          phx-click="switch_layout"
          phx-value-mode="blog"
          class={["tab", @layout_mode == :blog && "tab-active"]}
        >
          Blog
        </button>
        <button
          phx-click="switch_layout"
          phx-value-mode="minimal"
          class={["tab", @layout_mode == :minimal && "tab-active"]}
        >
          Minimal
        </button>
      </div>

      <%!-- SDUI renders the post display in selected layout mode --%>
      <.sdui_root tree={@__sdui_tree__} />

      <%!-- Comment form — native Phoenix, not SDUI (forms are not server-driven) --%>
      <div class="mt-8">
        <div class="divider">Add a comment</div>
        <div class="card bg-base-100 shadow border border-base-300 max-w-2xl">
          <div class="card-body">
            <form phx-change="validate_comment" phx-submit="submit_comment" class="space-y-4">
              <fieldset class="fieldset">
                <legend class="fieldset-legend">Your comment</legend>
                <textarea
                  name={@comment_form[:body].name}
                  placeholder="Write a comment..."
                  class={"textarea textarea-bordered w-full h-28 #{if @comment_form[:body].errors != [], do: "textarea-error"}"}
                  phx-debounce="300"
                ><%= Phoenix.HTML.Form.input_value(@comment_form, :body) %></textarea>
                <%= for error <- @comment_form[:body].errors do %>
                  <p class="label text-error text-xs"><%= translate_error(error) %></p>
                <% end %>
              </fieldset>
              <div class="flex justify-end">
                <button type="submit" class="btn btn-primary btn-sm">Post Comment</button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp sdui_root(assigns) do
    AshSDUI.Components.SDUIRoot.render(assigns)
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
