defmodule SduiDemoWeb.Live.PostFormLive do
  use SduiDemoWeb, :live_view

  alias SduiDemo.Blog
  alias SduiDemo.Blog.Post
  alias SduiDemo.Accounts
  alias SduiDemo.Accounts.User

  @impl true
  def mount(params, _session, socket) do
    demo_user = get_demo_user()

    socket =
      socket
      |> assign(:demo_user, demo_user)
      |> assign(:page_title, page_title(socket.assigns.live_action))

    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    form =
      Post
      |> AshPhoenix.Form.for_create(:create,
        domain: Blog,
        as: "post"
      )

    assign(socket, form: to_form(form), post: nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    case Ash.get(Post, id, domain: Blog) do
      {:ok, post} ->
        form =
          post
          |> AshPhoenix.Form.for_update(:update,
            domain: Blog,
            as: "post"
          )

        assign(socket, form: to_form(form), post: post)

      {:error, _} ->
        socket
        |> put_flash(:error, "Post not found.")
        |> push_navigate(to: "/posts")
    end
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, post_params)
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    params =
      case socket.assigns.live_action do
        :new ->
          demo_user = socket.assigns.demo_user

          %{
            "title" => post_params["title"] || "",
            "body" => post_params["body"] || ""
          }
          |> maybe_put("author_id", demo_user && to_string(demo_user.id))
          |> maybe_put("published_at", if(post_params["publish"] == "true", do: DateTime.to_iso8601(DateTime.utc_now())))

        :edit ->
          post_params
      end

    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, success_message(socket.assigns.live_action))
         |> push_navigate(to: "/posts/#{post.id}")}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp get_demo_user do
    case Ash.read(User, domain: Accounts) do
      {:ok, [user | _]} -> user
      _ -> nil
    end
  end

  defp page_title(:new), do: "New Post"
  defp page_title(:edit), do: "Edit Post"

  defp success_message(:new), do: "Post created!"
  defp success_message(:edit), do: "Post updated."

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <div class="flex items-center gap-3 mb-6">
        <a href="/posts" class="btn btn-ghost btn-sm">← Posts</a>
        <h1 class="text-2xl font-bold"><%= @page_title %></h1>
      </div>

      <div class="card bg-base-100 shadow-md border border-base-300">
        <div class="card-body">
          <form phx-change="validate" phx-submit="save" class="space-y-5">
            <fieldset class="fieldset">
              <legend class="fieldset-legend">Title</legend>
              <input
                type="text"
                name={@form[:title].name}
                value={Phoenix.HTML.Form.input_value(@form, :title)}
                placeholder="Enter post title"
                class={"input input-bordered w-full #{if @form[:title].errors != [], do: "input-error"}"}
                phx-debounce="300"
              />
              <%= for error <- @form[:title].errors do %>
                <p class="label text-error text-xs"><%= translate_error(error) %></p>
              <% end %>
            </fieldset>

            <fieldset class="fieldset">
              <legend class="fieldset-legend">Body</legend>
              <textarea
                name={@form[:body].name}
                placeholder="Write your post content here..."
                class={"textarea textarea-bordered w-full h-48 #{if @form[:body].errors != [], do: "textarea-error"}"}
                phx-debounce="300"
              ><%= Phoenix.HTML.Form.input_value(@form, :body) %></textarea>
              <%= for error <- @form[:body].errors do %>
                <p class="label text-error text-xs"><%= translate_error(error) %></p>
              <% end %>
            </fieldset>

            <%= if @live_action == :new do %>
              <fieldset class="fieldset">
                <label class="label cursor-pointer justify-start gap-3">
                  <input
                    type="checkbox"
                    name="post[publish]"
                    value="true"
                    class="checkbox checkbox-primary"
                  />
                  <span class="label-text">Publish immediately</span>
                </label>
              </fieldset>
            <% end %>

            <%= if @live_action == :edit && @post do %>
              <div class="alert alert-info text-sm">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>
                  Status:
                  <%= if @post.published_at do %>
                    <span class="badge badge-success badge-sm">Published <%= Calendar.strftime(@post.published_at, "%b %d, %Y") %></span>
                  <% else %>
                    <span class="badge badge-warning badge-sm">Draft</span>
                  <% end %>
                </span>
              </div>
            <% end %>

            <div class="flex justify-end gap-3 pt-2">
              <a href="/posts" class="btn btn-ghost">Cancel</a>
              <button type="submit" class="btn btn-primary">
                <%= if @live_action == :new, do: "Create Post", else: "Save Changes" %>
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
