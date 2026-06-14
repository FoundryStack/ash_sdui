defmodule AshSDUI.LiveResource do
  @moduledoc """
  Generic LiveView engine for AshSDUI resource screens.

  Use it from an app LiveView module:

      defmodule MyAppWeb.PostsLive do
        use AshSDUI.LiveResource,
          resource: MyApp.UI.PostUI,
          screen: :index,
          return_to: "/posts"
      end

  The engine handles conventional index/show/new/edit flows and renders the
  package DaisyUI components. Applications can still override any callback in
  the generated LiveView module.
  """

  defmacro __using__(opts) do
    normalized_opts = normalize_using_opts(opts, __CALLER__)
    resource = Keyword.fetch!(opts, :resource)
    screen = Keyword.get(opts, :screen, :index)
    escaped_opts = Macro.escape(normalized_opts)

    quote do
      use Phoenix.LiveView

      @ash_sdui_resource unquote(resource)
      @ash_sdui_screen unquote(screen)
      @ash_sdui_opts unquote(escaped_opts)

      @impl true
      def mount(params, session, socket) do
        AshSDUI.LiveResource.mount_resource(
          __MODULE__,
          @ash_sdui_resource,
          @ash_sdui_screen,
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
      def render(assigns) do
        AshSDUI.LiveResource.render_resource(assigns)
      end

      def ash_sdui_context(_params, _session, _socket), do: %{}

      def ash_sdui_transform_form_params(_mode, params, _socket), do: params

      def ash_sdui_after_save(record, socket) do
        AshSDUI.LiveResource.default_after_save(socket, record)
      end

      def ash_sdui_load_assigns(_mode, _params, _socket), do: %{}

      def ash_sdui_screen_opts(_mode, _params, _session, _socket), do: []

      defoverridable mount: 3,
                     handle_event: 3,
                     render: 1,
                     ash_sdui_context: 3,
                     ash_sdui_transform_form_params: 3,
                     ash_sdui_after_save: 2,
                     ash_sdui_load_assigns: 3,
                     ash_sdui_screen_opts: 4
    end
  end

  import Phoenix.Component
  import Phoenix.LiveView

  alias AshSDUI.Context
  alias AshSDUI.Screen

  def mount_resource(owner, resource_ui, mode, opts, params, session, socket) do
    context = context_from(owner, opts, params, session, socket)
    runtime_screen_opts = owner.ash_sdui_screen_opts(mode, params, session, socket)

    screen_opts =
      opts
      |> Keyword.take([
        :recipe,
        :variant_resolvers,
        :field_overrides,
        :action_overrides,
        :recipe_overrides,
        :assigns
      ])
      |> Keyword.merge(runtime_screen_opts)
      |> Keyword.put(:context, context)

    with {:ok, screen} <- Screen.resolve(resource_ui, mode, screen_opts),
         {:ok, socket} <- assign_data(socket, screen, opts, params) do
      {:ok,
       socket
       |> assign(:ash_sdui_resource_ui, resource_ui)
       |> assign(:ash_sdui_resource, screen.resource)
       |> assign(:ash_sdui_screen, screen)
       |> assign(:ash_sdui_mode, mode)
       |> assign(:ash_sdui_opts, opts)
       |> assign(:page_title, screen.assigns[:title])
       |> maybe_assign_layout(screen)
       |> then(&assign_hook_assigns(owner, mode, params, &1))}
    else
      {:error, reason} ->
        {:ok,
         socket
         |> assign(:ash_sdui_error, reason)
         |> assign(:ash_sdui_screen, nil)
         |> assign(:ash_sdui_mode, mode)
         |> assign(:ash_sdui_opts, opts)}
    end
  end

  def handle_resource_event(_owner, "validate", params, socket) do
    form_name = form_name(socket.assigns.ash_sdui_resource)
    form_params = Map.get(params, form_name, %{})
    form = ash_phoenix_form!().validate(socket.assigns.form.source, form_params)
    {:noreply, assign(socket, :form, Phoenix.Component.to_form(form))}
  end

  def handle_resource_event(owner, "save", params, socket) do
    form_name = form_name(socket.assigns.ash_sdui_resource)

    form_params =
      owner.ash_sdui_transform_form_params(
        socket.assigns.ash_sdui_mode,
        Map.get(params, form_name, %{}),
        socket
      )

    case ash_phoenix_form!().submit(socket.assigns.form.source, params: form_params) do
      {:ok, record} ->
        {:noreply, owner.ash_sdui_after_save(record, socket)}

      {:error, form} ->
        {:noreply, assign(socket, :form, Phoenix.Component.to_form(form))}
    end
  end

  def handle_resource_event(_owner, "delete", %{"id" => id}, socket) do
    resource = socket.assigns.ash_sdui_resource

    with {:ok, record} <-
           Ash.get(
             resource,
             id,
             ash_opts(
               resource,
               socket.assigns.ash_sdui_screen.context,
               socket.assigns.ash_sdui_opts
             )
           ),
         :ok <- Ash.destroy(record) do
      {:noreply,
       socket
       |> put_flash(:info, "Deleted.")
       |> reload_index()}
    else
      _ -> {:noreply, put_flash(socket, :error, "Could not delete record.")}
    end
  end

  def handle_resource_event(_owner, _event, _params, socket), do: {:noreply, socket}

  def render_resource(%{ash_sdui_error: reason} = assigns) do
    assigns = assign(assigns, :reason, inspect(reason))

    ~H"""
    <div class="alert alert-error">{@reason}</div>
    """
  end

  def render_resource(%{__sdui_tree__: tree} = assigns) when not is_nil(tree) do
    ~H"""
    <AshSDUI.Components.SDUIRoot.render
      tree={@__sdui_tree__}
      context={@ash_sdui_screen.context}
      domain={root_domain(@ash_sdui_resource, @ash_sdui_opts)}
    />
    """
  end

  def render_resource(%{ash_sdui_mode: mode} = assigns) when mode in [:new, :edit] do
    content_class = recipe_class(assigns.ash_sdui_screen, :content)
    assigns = assign(assigns, :content_class, content_class)

    ~H"""
    <div class="space-y-6">
      <AshSDUI.Components.ResourceForm.render
        form={@form}
        resource={@ash_sdui_resource_ui}
        action={@ash_sdui_screen.action}
        fields={@ash_sdui_screen.fields}
        class={@content_class}
      >
        <:footer>
          <div class="flex justify-end">
            <button type="submit" class="btn btn-primary">Save</button>
          </div>
        </:footer>
      </AshSDUI.Components.ResourceForm.render>
    </div>
    """
  end

  def render_resource(%{ash_sdui_mode: :show} = assigns) do
    toolbar_hidden? = recipe_hidden?(assigns.ash_sdui_screen, :toolbar)
    toolbar_class = recipe_class(assigns.ash_sdui_screen, :toolbar)
    content_class = recipe_class(assigns.ash_sdui_screen, :content)

    assigns =
      assigns
      |> assign(:toolbar_hidden?, toolbar_hidden?)
      |> assign(:toolbar_class, toolbar_class)
      |> assign(:content_class, content_class)

    ~H"""
    <div class="space-y-6">
      <AshSDUI.Components.ResourceActions.render
        :if={!@toolbar_hidden?}
        resource={@ash_sdui_resource_ui}
        subject={@subject}
        actions={@ash_sdui_screen.actions}
        placement={:toolbar}
        class={@toolbar_class}
      />
      <AshSDUI.Components.ResourceDetail.render
        subject={@subject}
        fields={@ash_sdui_screen.fields}
        class={@content_class}
      />
    </div>
    """
  end

  def render_resource(assigns) do
    toolbar_hidden? = recipe_hidden?(assigns.ash_sdui_screen, :toolbar)
    toolbar_class = recipe_class(assigns.ash_sdui_screen, :toolbar)
    content_class = recipe_class(assigns.ash_sdui_screen, :content)

    assigns =
      assigns
      |> assign(:toolbar_hidden?, toolbar_hidden?)
      |> assign(:toolbar_class, toolbar_class)
      |> assign(:content_class, content_class)

    ~H"""
    <div class="space-y-6">
      <AshSDUI.Components.ResourceActions.render
        :if={!@toolbar_hidden?}
        resource={@ash_sdui_resource_ui}
        actions={@ash_sdui_screen.actions}
        placement={:toolbar}
        class={@toolbar_class}
      />
      <AshSDUI.Components.ResourceCollection.render
        records={@records}
        fields={@ash_sdui_screen.fields}
        actions={@ash_sdui_screen.actions}
        resource={@ash_sdui_resource_ui}
        empty_title={@ash_sdui_screen.assigns[:empty_state] || "No records"}
        empty_body={@ash_sdui_screen.assigns[:empty_state_body]}
        class={@content_class}
      />
    </div>
    """
  end

  def default_after_save(socket, record), do: after_save(socket, record)

  defp assign_data(socket, %Screen{mode: :index} = screen, opts, _params) do
    case Ash.read(
           screen.resource,
           ash_opts(screen.resource, screen.context, opts) ++ action_opt(screen.action)
         ) do
      {:ok, records} -> {:ok, assign(socket, :records, records)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp assign_data(socket, %Screen{mode: :show} = screen, opts, %{"id" => id}) do
    case Ash.get(screen.resource, id, ash_opts(screen.resource, screen.context, opts)) do
      {:ok, subject} -> {:ok, assign(socket, :subject, subject)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp assign_data(socket, %Screen{mode: mode} = screen, opts, params)
       when mode in [:new, :edit] do
    with {:ok, %{form: form, subject: subject}} <- build_form(screen, opts, params) do
      {:ok,
       socket
       |> assign(:form, Phoenix.Component.to_form(form))
       |> assign(:subject, subject)}
    end
  end

  defp assign_data(socket, _screen, _opts, _params), do: {:ok, socket}

  defp maybe_assign_layout(socket, %Screen{assigns: %{layout: :sdui}} = screen) do
    layout_opts =
      []
      |> maybe_put_layout_opt(:records, socket.assigns[:records])
      |> maybe_put_layout_opt(:subject, socket.assigns[:subject])

    case Screen.to_layout(screen, layout_opts) do
      {:ok, layout} ->
        assign(socket, :__sdui_tree__, AshSDUI.Layout.Builder.to_tree(layout))

      {:error, _reason} ->
        socket
    end
  end

  defp maybe_assign_layout(socket, _screen), do: socket

  defp build_form(%Screen{mode: :new} = screen, opts, _params) do
    form =
      ash_phoenix_form!().for_create(
        screen.resource,
        screen.action,
        ash_opts(screen.resource, screen.context, opts) ++ [as: form_name(screen.resource)]
      )

    {:ok, %{form: form, subject: nil}}
  rescue
    error -> {:error, error}
  end

  defp build_form(%Screen{mode: :edit} = screen, opts, %{"id" => id}) do
    with {:ok, subject} <-
           Ash.get(screen.resource, id, ash_opts(screen.resource, screen.context, opts)) do
      form =
        ash_phoenix_form!().for_update(
          subject,
          screen.action,
          ash_opts(screen.resource, screen.context, opts) ++ [as: form_name(screen.resource)]
        )

      {:ok, %{form: form, subject: subject}}
    end
  rescue
    error -> {:error, error}
  end

  defp after_save(socket, record) do
    return_to = Keyword.get(socket.assigns.ash_sdui_opts, :return_to)

    socket = put_flash(socket, :info, "Saved.")

    if return_to do
      push_navigate(socket, to: replace_id(return_to, record))
    else
      socket
    end
  end

  defp reload_index(
         %{assigns: %{ash_sdui_mode: :index, ash_sdui_screen: screen, ash_sdui_opts: opts}} =
           socket
       ) do
    case Ash.read(
           screen.resource,
           ash_opts(screen.resource, screen.context, opts) ++ action_opt(screen.action)
         ) do
      {:ok, records} -> assign(socket, :records, records)
      {:error, _reason} -> socket
    end
  end

  defp reload_index(socket), do: socket

  defp context_from(owner, opts, params, session, socket) do
    assigns = Map.get(socket, :assigns, %{})

    extra_context =
      owner.ash_sdui_context(params, session, socket)
      |> Enum.into(%{})

    opts
    |> Keyword.get(:context, [])
    |> Enum.into(%{})
    |> Map.merge(%{
      actor: Keyword.get(opts, :actor) || session["actor"] || assigns[:current_user],
      tenant: Keyword.get(opts, :tenant) || session["tenant"] || assigns[:tenant],
      locale: Keyword.get(opts, :locale) || session["locale"],
      audience: Keyword.get(opts, :audience),
      device: Keyword.get(opts, :device)
    })
    |> Map.merge(extra_context)
    |> Context.new()
  end

  defp ash_opts(resource, context, opts) do
    []
    |> maybe_put(:domain, Keyword.get(opts, :domain) || resource_domain(resource))
    |> maybe_put(:actor, context.actor)
    |> maybe_put(:tenant, context.tenant)
  end

  defp resource_domain(resource) do
    Ash.Resource.Info.domain(resource)
  rescue
    _ -> nil
  end

  defp root_domain(resource, opts) do
    Keyword.get(opts, :domain) || resource_domain(resource)
  end

  defp action_opt(nil), do: []
  defp action_opt(action), do: [action: action]

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp maybe_put_layout_opt(opts, _key, nil), do: opts
  defp maybe_put_layout_opt(opts, key, value), do: Keyword.put(opts, key, value)

  defp recipe_hidden?(screen, section) do
    screen.assigns
    |> Map.get(:recipe_overrides, %{})
    |> Map.get(section, %{})
    |> Map.get(:skip?, false)
  end

  defp recipe_class(screen, section) do
    screen.assigns
    |> Map.get(:recipe_overrides, %{})
    |> Map.get(section, %{})
    |> Map.get(:props, %{})
    |> Map.get(:class)
  end

  defp form_name(resource) do
    resource |> Module.split() |> List.last() |> Macro.underscore()
  end

  defp replace_id(path, nil), do: path
  defp replace_id(path, record), do: String.replace(path, ":id", to_string(record.id))

  defp ash_phoenix_form! do
    module = Module.concat([AshPhoenix, Form])

    if Code.ensure_loaded?(module) do
      module
    else
      raise "AshSDUI.LiveResource form screens require ash_phoenix"
    end
  end

  defp assign_hook_assigns(owner, mode, params, socket) do
    assigns =
      owner.ash_sdui_load_assigns(mode, params, socket)
      |> Enum.into(%{})

    assign(socket, assigns)
  end

  defp normalize_using_opts(opts, caller) do
    Enum.map(opts, fn
      {key, value} when key in [:resource, :domain] -> {key, Macro.expand(value, caller)}
      pair -> pair
    end)
  end
end
