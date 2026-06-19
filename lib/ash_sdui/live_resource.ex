defmodule AshSDUI.LiveResource do
  @moduledoc """
  Generic LiveView engine for AshSDUI generated views.

  Use it from an app LiveView module:

      defmodule MyAppWeb.PostsLive do
        use AshSDUI.LiveResource,
          ui: MyApp.UI.PostUI,
          view: :index,
          return_to: "/posts"
      end
  """

  defmacro __using__(opts) do
    normalized_opts = normalize_using_opts(opts, __CALLER__)
    ui = Keyword.fetch!(opts, :ui)
    view = Keyword.get(opts, :view, :index)
    escaped_opts = Macro.escape(normalized_opts)

    quote do
      use Phoenix.LiveView

      @ash_sdui_ui unquote(ui)
      @ash_sdui_view unquote(view)
      @ash_sdui_opts unquote(escaped_opts)

      @impl true
      def mount(params, session, socket) do
        AshSDUI.LiveResource.mount_resource(
          __MODULE__,
          @ash_sdui_ui,
          @ash_sdui_view,
          @ash_sdui_opts,
          params,
          session,
          socket
        )
      end

      @impl true
      def handle_event(event, params, socket) do
        AshSDUI.LiveResource.handle_resource_event(__MODULE__, event, params, socket)
      end

      @impl true
      def handle_params(params, uri, socket) do
        AshSDUI.LiveResource.handle_resource_params(__MODULE__, params, uri, socket)
      end

      @impl true
      def handle_info(message, socket) do
        AshSDUI.LiveResource.handle_resource_info(__MODULE__, message, socket)
      end

      @impl true
      def render(assigns) do
        AshSDUI.LiveResource.render_resource(assigns)
      end

      def ash_sdui_context(_params, _session, _socket), do: %{}
      def ash_sdui_transform_form_params(_mode, params, _socket), do: params

      def ash_sdui_after_save(record, socket),
        do: AshSDUI.LiveResource.default_after_save(socket, record)

      def ash_sdui_load_assigns(_mode, _params, _socket), do: %{}
      def ash_sdui_view_opts(_mode, _params, _session, _socket), do: []

      defoverridable mount: 3,
                     handle_event: 3,
                     handle_info: 2,
                     handle_params: 3,
                     render: 1,
                     ash_sdui_context: 3,
                     ash_sdui_transform_form_params: 3,
                     ash_sdui_after_save: 2,
                     ash_sdui_load_assigns: 3,
                     ash_sdui_view_opts: 4
    end
  end

  import Phoenix.Component
  import Phoenix.LiveView

  alias AshSDUI.LiveResource.Events
  alias AshSDUI.LiveResource.Runtime
  alias AshSDUI.LiveResource.Subscriptions

  def mount_resource(owner, ui, mode, opts, params, session, socket) do
    Runtime.mount(owner, ui, mode, opts, params, session, socket)
  end

  def handle_resource_params(owner, params, uri, %{assigns: %{ash_sdui_ui: ui}} = socket)
      when not is_nil(ui) do
    mode = socket.assigns.ash_sdui_mode
    opts = socket.assigns.ash_sdui_opts
    session = socket.assigns[:ash_sdui_session] || %{}

    case Runtime.refresh(owner, ui, mode, opts, params, session, socket) do
      {:ok, refreshed} ->
        {:noreply, assign(refreshed, :ash_sdui_uri, uri)}

      {:error, reason} ->
        {:noreply, assign(socket, :ash_sdui_error, reason) |> assign(:ash_sdui_uri, uri)}
    end
  end

  def handle_resource_params(_owner, _params, uri, socket) do
    {:noreply, assign(socket, :ash_sdui_uri, uri)}
  end

  def handle_resource_info(owner, message, socket) do
    Subscriptions.handle_info(owner, message, socket)
  end

  def handle_resource_event(owner, event, params, socket),
    do: Events.handle(owner, event, params, socket)

  def render_resource(%{ash_sdui_error: reason} = assigns) do
    AshSDUI.LiveResource.Render.render_error(assigns, reason)
  end

  def render_resource(%{__sdui_tree__: tree} = assigns) when not is_nil(tree) do
    AshSDUI.LiveResource.Render.render_tree(assigns)
  end

  def render_resource(%{ash_sdui_mode: mode} = assigns) when mode in [:new, :edit] do
    AshSDUI.LiveResource.Render.render_form(assigns)
  end

  def render_resource(%{ash_sdui_mode: :show} = assigns) do
    AshSDUI.LiveResource.Render.render_show(assigns)
  end

  def render_resource(assigns) do
    AshSDUI.LiveResource.Render.render_index(assigns)
  end

  def default_after_save(socket, record), do: after_save(socket, record)

  defp after_save(socket, record) do
    return_to = Keyword.get(socket.assigns.ash_sdui_opts, :return_to)
    socket = put_flash(socket, :info, "Saved.")

    if return_to do
      push_navigate(socket, to: replace_id(return_to, record))
    else
      socket
    end
  end

  def root_domain(resource, opts) do
    Runtime.root_domain(resource, opts)
  end

  defp normalize_using_opts(opts, env) do
    Enum.map(opts, fn
      {key, value} -> {key, normalize_macro_value(value, env)}
      other -> other
    end)
  end

  defp normalize_macro_value(value, env) do
    value
    |> Macro.expand(env)
    |> then(fn expanded ->
      try do
        case Code.eval_quoted(expanded, [], env) do
          {result, _binding} -> result
        end
      rescue
        _ -> expanded
      end
    end)
  end

  defp replace_id(path, nil), do: path
  defp replace_id(path, record), do: String.replace(path, ":id", to_string(record.id))
end
