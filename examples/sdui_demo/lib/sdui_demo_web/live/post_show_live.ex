defmodule SduiDemoWeb.Live.PostShowLive do
  use SduiDemoWeb, :live_view

  alias SduiDemo.Blog
  alias SduiDemo.Blog.{Post, Comment}
  alias SduiDemo.Accounts
  alias SduiDemo.Accounts.User
  alias AshSDUI.LiveScreen
  alias SduiDemo.UI.Layouts.PostShowLayout

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case load_post(id) do
      {:ok, post, comments} ->
        demo_user = get_demo_user()

        {:ok,
         socket
         |> assign_post_state(post, comments, :standard)
         |> assign(:comment_form, fresh_comment_form())
         |> assign(:demo_user, demo_user)
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

    {:noreply, assign_post_state(socket, post, comments, mode)}
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
        case reload_post_state(socket, to_string(post.id), "Comment added!") do
          {:ok, refreshed_socket} ->
            {:noreply, assign(refreshed_socket, :comment_form, fresh_comment_form())}

          {:error, redirected_socket} ->
            {:noreply, redirected_socket}
        end

      {:error, form} ->
        {:noreply, assign(socket, :comment_form, to_form(form))}
    end
  end

  @impl true
  def handle_event("publish", _params, socket) do
    post = socket.assigns.post

    case Ash.update(post, %{}, action: :publish, domain: Blog) do
      {:ok, updated_post} ->
        case reload_post_state(socket, to_string(updated_post.id), "Post published!") do
          {:ok, refreshed_socket} -> {:noreply, refreshed_socket}
          {:error, redirected_socket} -> {:noreply, redirected_socket}
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

  defp fresh_comment_form do
    Comment
    |> AshPhoenix.Form.for_create(:create, domain: Blog, as: "comment")
    |> to_form()
  end

  defp reload_post_state(socket, post_id, flash_message) do
    case load_post(post_id) do
      {:ok, post, comments} ->
        {:ok,
         socket
         |> assign_post_state(post, comments, socket.assigns.layout_mode)
         |> put_flash(:info, flash_message)}

      :not_found ->
        {:error, push_navigate(socket, to: "/posts")}
    end
  end

  defp assign_post_state(socket, post, comments, mode) do
    {layout_name, root} = PostShowLayout.build(post, comments, mode: mode)

    socket
    |> assign(:post, post)
    |> assign(:comments, comments)
    |> assign(:layout_mode, mode)
    |> LiveScreen.assign_layout(layout_name, root)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-6xl px-4 py-10 sm:px-6">
      <div class="space-y-8">
        <.post_show_action_bar post={@post} layout_mode={@layout_mode} />

        <.sdui_root tree={@__sdui_tree__} />

        <section class="space-y-4">
          <div class="space-y-1">
            <h2 class="text-2xl font-semibold text-base-content">Add a comment</h2>
            <p class="text-sm text-base-content/65">
              The show page stays custom on purpose, which makes it a good example of how generated and hand-shaped flows can live together.
            </p>
          </div>
          <div class="card max-w-2xl border border-base-300 bg-base-100 shadow-sm">
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
                    <p class="label text-error text-xs">{translate_error(error)}</p>
                  <% end %>
                </fieldset>
                <div class="flex justify-end">
                  <button type="submit" class="btn btn-primary btn-sm">Post Comment</button>
                </div>
              </form>
            </div>
          </div>
        </section>
      </div>
    </div>
    """
  end

  defp post_show_action_bar(assigns) do
    SduiDemoWeb.Components.Layouts.PostShowActionBar.render(assigns)
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
