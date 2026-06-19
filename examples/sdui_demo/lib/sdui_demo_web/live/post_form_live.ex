defmodule SduiDemoWeb.Live.PostFormLive do
  use AshSDUI.LiveResource,
    ui: SduiDemo.UI.Resources.PostUI,
    view: :new,
    domain: SduiDemo.Blog

  alias SduiDemo.Accounts
  alias SduiDemo.Accounts.User

  @resource_ui SduiDemo.UI.Resources.PostUI
  @domain SduiDemo.Blog

  @impl true
  def mount(params, session, socket) do
    mode = socket.assigns.live_action

    AshSDUI.LiveResource.mount_resource(
      __MODULE__,
      @resource_ui,
      mode,
      live_resource_opts(mode),
      params,
      session,
      socket
    )
  end

  def ash_sdui_load_assigns(_mode, _params, socket) do
    %{
      demo_user: get_demo_user(),
      post: socket.assigns[:subject]
    }
  end

  def ash_sdui_view_opts(mode, _params, _session, _socket) do
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
  def render(%{ash_sdui_error: reason} = assigns) when not is_nil(reason) do
    AshSDUI.LiveResource.Render.render_error(assigns, reason)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.post_form_page_layout
      page_title={resolved_page_title(assigns)}
      form={@form}
      fields={resolved_fields(assigns)}
      live_action={@live_action}
      post={@subject || @post}
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
    [ui: @resource_ui, view: mode, domain: @domain]
  end

  defp resolved_page_title(%{page_title: title}) when is_binary(title), do: title
  defp resolved_page_title(%{live_action: live_action}), do: page_title(live_action)

  defp resolved_fields(%{ash_sdui_view: %{fields: fields}}) when is_list(fields), do: fields
  defp resolved_fields(_assigns), do: []

  defp post_form_page_layout(assigns) do
    SduiDemoWeb.Components.Layouts.PostFormPageLayout.render(assigns)
  end
end
