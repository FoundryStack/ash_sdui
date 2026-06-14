defmodule SduiDemoWeb.Live.PostFormLive do
  use AshSDUI.LiveResource,
    resource: SduiDemo.UI.Resources.PostUI,
    screen: :new,
    domain: SduiDemo.Blog

  alias SduiDemo.Accounts
  alias SduiDemo.Accounts.User

  @resource_ui SduiDemo.UI.Resources.PostUI
  @domain SduiDemo.Blog

  @impl true
  def mount(params, session, socket) do
    mode = socket.assigns.live_action
    AshSDUI.LiveResource.mount_resource(__MODULE__, @resource_ui, mode, live_resource_opts(mode), params, session, socket)
  end

  def ash_sdui_load_assigns(_mode, _params, socket) do
    %{
      demo_user: get_demo_user(),
      post: socket.assigns[:subject]
    }
  end

  def ash_sdui_screen_opts(mode, _params, _session, _socket) do
    [
      recipe_overrides: [
        title: page_title(mode)
      ]
    ]
  end

  def ash_sdui_transform_form_params(:new, params, socket) do
    demo_user = socket.assigns.demo_user

    %{
      "title" => Map.get(params, "title", ""),
      "body" => Map.get(params, "body", "")
    }
    |> maybe_put("author_id", demo_user && to_string(demo_user.id))
    |> maybe_put(
      "published_at",
      if(Map.get(params, "publish") == "true", do: DateTime.to_iso8601(DateTime.utc_now()))
    )
  end

  def ash_sdui_transform_form_params(:edit, params, _socket), do: Map.delete(params, "publish")

  def ash_sdui_after_save(record, socket) do
    socket
    |> Phoenix.LiveView.put_flash(:info, success_message(socket.assigns.ash_sdui_mode))
    |> Phoenix.LiveView.push_navigate(to: "/posts/#{record.id}")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.post_form_page_layout
      page_title={@ash_sdui_screen.assigns.title}
      form={@form}
      fields={@ash_sdui_screen.fields}
      live_action={@live_action}
      post={@post}
    />
    """
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

  defp live_resource_opts(mode) do
    [resource: @resource_ui, screen: mode, domain: @domain]
  end

  defp post_form_page_layout(assigns) do
    SduiDemoWeb.Components.Layouts.PostFormPageLayout.render(assigns)
  end
end
