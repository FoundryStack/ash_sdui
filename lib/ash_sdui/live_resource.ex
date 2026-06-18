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

  alias AshSDUI.Context
  alias AshSDUI.Intent
  alias AshSDUI.Query
  alias AshSDUI.Runtime.BindingSet
  alias AshSDUI.Runtime.Normalize
  alias AshSDUI.Runtime.State, as: RuntimeState
  alias AshSDUI.View

  def mount_resource(owner, ui, mode, opts, params, session, socket) do
    context = context_from(owner, opts, params, session, socket)
    runtime_view_opts = owner.ash_sdui_view_opts(mode, params, session, socket)

    view_opts =
      opts
      |> Keyword.take([
        :recipe,
        :variant_resolvers,
        :field_overrides,
        :intent_overrides,
        :recipe_overrides,
        :assigns
      ])
      |> Keyword.merge(runtime_view_opts)
      |> Keyword.put(:context, context)
      |> Keyword.put(:params, params)

    with {:ok, view} <- View.resolve(ui, mode, view_opts),
         {:ok, bindings} <- load_bindings(view, opts, params),
         runtime_view = enrich_view(view, bindings),
         {:ok, socket} <- assign_data(socket, runtime_view, bindings, opts, params) do
      socket =
        socket
        |> assign(:ash_sdui_subscription_specs, subscription_specs(runtime_view, opts))
        |> register_subscriptions(runtime_view, opts)

      {:ok,
       socket
       |> assign(:ash_sdui_ui, ui)
       |> assign(:ash_sdui_resource, runtime_view.resource)
       |> assign(:ash_sdui_bindings, bindings)
       |> assign(:ash_sdui_context, runtime_view.context)
       |> assign(:ash_sdui_state, runtime_view.state)
       |> assign(:ash_sdui_view, runtime_view)
       |> assign(:ash_sdui_mode, mode)
       |> assign(:ash_sdui_opts, opts)
       |> assign(:ash_sdui_session, session)
       |> assign(:ash_sdui_params, params)
       |> assign_new(:ash_sdui_uri, fn -> nil end)
       |> assign(:page_title, runtime_view.assigns[:title])
       |> maybe_assign_layout(runtime_view)
       |> then(&assign_hook_assigns(owner, mode, params, &1))}
    else
      {:error, reason} ->
        {:ok,
         socket
         |> assign(:ash_sdui_error, reason)
         |> assign(:ash_sdui_view, nil)
         |> assign(:ash_sdui_mode, mode)
         |> assign(:ash_sdui_opts, opts)
         |> assign(:ash_sdui_session, session)
         |> assign(:ash_sdui_params, params)}
    end
  end

  def handle_resource_params(owner, params, uri, %{assigns: %{ash_sdui_ui: ui}} = socket)
      when not is_nil(ui) do
    mode = socket.assigns.ash_sdui_mode
    opts = socket.assigns.ash_sdui_opts
    session = socket.assigns[:ash_sdui_session] || %{}

    case refresh_resource(owner, ui, mode, opts, params, session, socket) do
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
    case apply_live_message(owner, socket, message) do
      {:ok, socket} -> {:noreply, socket}
      :ignore -> {:noreply, socket}
      {:error, reason} -> {:noreply, put_flash(socket, :error, inspect(reason))}
    end
  end

  def handle_resource_event(_owner, "validate", params, socket) do
    form_name = form_name(socket.assigns.ash_sdui_resource)
    form_params = Map.get(params, form_name, %{})
    form = ash_phoenix_form!().validate(socket.assigns.form.source, form_params)
    {:noreply, assign(socket, :form, Phoenix.Component.to_form(form))}
  end

  def handle_resource_event(_owner, "query", params, %{assigns: %{ash_sdui_view: view}} = socket) do
    {:noreply, patch_query(socket, Query.update(view.state.query, :params, params))}
  end

  def handle_resource_event(_owner, "sort", %{"field" => field} = params, socket) do
    query = socket.assigns.ash_sdui_view.state.query
    direction = next_sort_direction(query, field, Map.get(params, "direction"))

    {:noreply,
     patch_query(socket, Query.update(query, :sort, %{"sort" => sort_param(field, direction)}))}
  end

  def handle_resource_event(_owner, "paginate", %{"offset" => offset}, socket) do
    query = socket.assigns.ash_sdui_view.state.query
    {:noreply, patch_query(socket, Query.update(query, :paginate, %{"offset" => offset}))}
  end

  def handle_resource_event(_owner, "reset_query", _params, socket) do
    query = socket.assigns.ash_sdui_view.state.query
    {:noreply, patch_query(socket, Query.update(query, :reset, %{}))}
  end

  def handle_resource_event(owner, "refresh", params, socket) do
    {:noreply, refresh_socket(owner, socket, params)}
  end

  def handle_resource_event(_owner, "select", params, socket) do
    {:noreply, update_selection(socket, params)}
  end

  def handle_resource_event(_owner, "workflow", params, socket) do
    {:noreply, update_workflow(socket, params)}
  end

  def handle_resource_event(owner, "intent", params, socket) do
    {:noreply, dispatch_intent(owner, params, socket)}
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
    view = socket.assigns.ash_sdui_view

    with {:ok, record} <-
           Ash.get(resource, id, ash_opts(resource, view.context, socket.assigns.ash_sdui_opts)),
         :ok <- Ash.destroy(record) do
      {:noreply, socket |> put_flash(:info, "Deleted.") |> reload_index()}
    else
      _ -> {:noreply, put_flash(socket, :error, "Could not delete record.")}
    end
  end

  def handle_resource_event(_owner, _event, _params, socket), do: {:noreply, socket}

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

  defp assign_data(socket, %View{mode: :index} = view, bindings, _opts, _params) do
    records = BindingSet.primary_collection(view, bindings) || []
    {:ok, assign(socket, :records, records)}
  end

  defp assign_data(socket, %View{mode: :show} = view, bindings, _opts, _params) do
    case BindingSet.primary_record(view, bindings) do
      nil -> {:error, :missing_subject}
      subject -> {:ok, assign(socket, :subject, subject)}
    end
  end

  defp assign_data(socket, %View{mode: mode} = view, bindings, opts, params)
       when mode in [:new, :edit] do
    with {:ok, %{form: form, subject: subject}} <- build_form(view, bindings, opts, params) do
      {:ok, socket |> assign(:form, Phoenix.Component.to_form(form)) |> assign(:subject, subject)}
    end
  end

  defp assign_data(socket, _view, _bindings, _opts, _params), do: {:ok, socket}

  defp maybe_assign_layout(socket, %View{assigns: %{layout: :sdui}} = view) do
    layout_opts =
      []
      |> Keyword.put(:bindings, socket.assigns[:ash_sdui_bindings] || %{})
      |> Keyword.put(:state, view.state)
      |> Keyword.put(:context, view.context)
      |> Normalize.maybe_put_keyword(:records, socket.assigns[:records])
      |> Normalize.maybe_put_keyword(:subject, socket.assigns[:subject])
      |> Normalize.maybe_put_keyword(:form, socket.assigns[:form])

    case View.to_layout(view, layout_opts) do
      {:ok, layout} -> assign(socket, :__sdui_tree__, AshSDUI.Layout.Builder.to_tree(layout))
      {:error, _reason} -> socket
    end
  end

  defp maybe_assign_layout(socket, _view), do: socket

  defp build_form(%View{mode: :new} = view, _bindings, opts, _params) do
    form =
      ash_phoenix_form!().for_create(
        view.resource,
        view.action,
        ash_opts(view.resource, view.context, opts) ++ [as: form_name(view.resource)]
      )

    {:ok, %{form: form, subject: nil}}
  rescue
    error -> {:error, error}
  end

  defp build_form(%View{mode: :edit} = view, bindings, opts, %{"id" => id}) do
    with {:ok, subject} <- resolve_edit_subject(view, bindings, opts, id) do
      form =
        ash_phoenix_form!().for_update(
          subject,
          view.action,
          ash_opts(view.resource, view.context, opts) ++ [as: form_name(view.resource)]
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
         %{assigns: %{ash_sdui_mode: :index, ash_sdui_view: view, ash_sdui_opts: opts}} = socket
       ) do
    params = socket.assigns[:ash_sdui_params] || %{}

    case load_bindings(view, opts, params) do
      {:ok, bindings} ->
        view = enrich_view(view, bindings)

        socket
        |> assign(:ash_sdui_bindings, bindings)
        |> assign(:ash_sdui_state, view.state)
        |> assign(:ash_sdui_view, view)
        |> assign(:records, BindingSet.primary_collection(view, bindings) || [])

      {:error, _reason} ->
        socket
    end
  end

  defp reload_index(socket), do: socket

  defp load_bindings(%View{mode: :new}, _opts, _params), do: {:ok, %{}}

  defp load_bindings(%View{} = view, opts, params) do
    base_opts = [
      actor: view.context.actor,
      tenant: view.context.tenant,
      domain: root_domain(view.resource, opts),
      record_id: params["id"] || params[:id]
    ]

    with {:ok, bindings} <- AshSDUI.Binding.load(view.bindings, base_opts) do
      case BindingSet.primary_record(view, bindings) do
        nil ->
          {:ok, bindings}

        record ->
          AshSDUI.Binding.load(view.bindings, Keyword.put(base_opts, :record, record))
      end
    end
  end

  defp resolve_edit_subject(view, bindings, opts, id) do
    case BindingSet.primary_record(view, bindings) do
      nil -> Ash.get(view.resource, id, ash_opts(view.resource, view.context, opts))
      subject -> {:ok, subject}
    end
  end

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
    |> Normalize.maybe_put_keyword(:domain, Keyword.get(opts, :domain) || resource_domain(resource))
    |> Normalize.maybe_put_keyword(:actor, context.actor)
    |> Normalize.maybe_put_keyword(:tenant, context.tenant)
  end

  defp resource_domain(resource) do
    Ash.Resource.Info.domain(resource)
  rescue
    _ -> nil
  end

  def root_domain(resource, opts) do
    Keyword.get(opts, :domain) || resource_domain(resource)
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
      raise "AshSDUI.LiveResource form views require ash_phoenix"
    end
  end

  defp normalize_using_opts(opts, env) do
    Enum.map(opts, fn
      {key, value} -> {key, normalize_macro_value(value, env)}
      other -> other
    end)
  end

  defp assign_hook_assigns(owner, mode, params, socket) do
    owner.ash_sdui_load_assigns(mode, params, socket)
    |> Enum.into(%{})
    |> then(&assign(socket, &1))
  end

  defp refresh_resource(owner, ui, mode, opts, params, session, socket) do
    context = context_from(owner, opts, params, session, socket)
    runtime_view_opts = owner.ash_sdui_view_opts(mode, params, session, socket)

    view_opts =
      opts
      |> Keyword.take([
        :recipe,
        :variant_resolvers,
        :field_overrides,
        :intent_overrides,
        :recipe_overrides,
        :assigns
      ])
      |> Keyword.merge(runtime_view_opts)
      |> Keyword.put(:context, context)
      |> Keyword.put(:params, params)

    with {:ok, view} <- View.resolve(ui, mode, view_opts),
         {:ok, bindings} <- load_bindings(view, opts, params),
         runtime_view = enrich_view(view, bindings),
         {:ok, socket} <- assign_data(socket, runtime_view, bindings, opts, params) do
      socket =
        socket
        |> assign(:ash_sdui_subscription_specs, subscription_specs(runtime_view, opts))
        |> register_subscriptions(runtime_view, opts)

      {:ok,
       socket
       |> assign(:ash_sdui_resource, runtime_view.resource)
       |> assign(:ash_sdui_bindings, bindings)
       |> assign(:ash_sdui_context, runtime_view.context)
       |> assign(:ash_sdui_state, runtime_view.state)
       |> assign(:ash_sdui_view, runtime_view)
       |> assign(:ash_sdui_params, params)
       |> assign(:page_title, runtime_view.assigns[:title])
       |> maybe_assign_layout(runtime_view)
       |> then(&assign_hook_assigns(owner, mode, params, &1))}
    end
  end

  defp enrich_view(%View{} = view, bindings) do
    state = view.state || %View.State{}

    state_assigns =
      state.assigns
      |> Map.merge(%{
        bindings: bindings,
        primary_collection: BindingSet.primary_collection(view, bindings),
        primary_record: BindingSet.primary_record(view, bindings)
      })

    %{view | state: %{state | assigns: state_assigns, refresh: RuntimeState.refresh_snapshot(bindings, state)}}
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

  defp patch_query(socket, nil), do: socket

  defp patch_query(socket, query) do
    path = socket.assigns[:ash_sdui_uri] |> current_path() |> merge_query_path(query)
    push_patch(socket, to: path)
  end

  defp current_path(nil), do: "/"

  defp current_path(uri) do
    parsed = URI.parse(uri)
    parsed.path || "/"
  end

  defp merge_query_path(path, %Query{} = query) do
    params =
      query.params
      |> normalize_query_params()
      |> Map.merge(query_params(query))
      |> Enum.reject(fn {_key, value} -> blank_query_value?(value) end)
      |> Enum.into(%{})

    case URI.encode_query(params) do
      "" -> path
      encoded -> path <> "?" <> encoded
    end
  end

  defp query_params(%Query{} = query) do
    %{}
    |> Normalize.maybe_put_map("search", query.search)
    |> Normalize.maybe_put_map("limit", query.limit)
    |> Normalize.maybe_put_map("offset", query.offset)
    |> Normalize.maybe_put_map("sort", sort_query_param(query.sort))
    |> Normalize.maybe_put_map("filters", stringify_keys(query.filters))
  end

  defp normalize_query_params(params) when is_map(params) do
    params
    |> Map.drop([
      "search",
      "sort",
      "limit",
      "offset",
      "filters",
      :search,
      :sort,
      :limit,
      :offset,
      :filters
    ])
    |> stringify_keys()
  end

  defp normalize_query_params(_params), do: %{}

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {
        if(is_atom(key), do: Atom.to_string(key), else: key),
        if(is_map(value), do: stringify_keys(value), else: value)
      }
    end)
  end

  defp stringify_keys(value), do: value

  defp sort_query_param([]), do: nil

  defp sort_query_param(sort) do
    Enum.map_join(sort, ",", fn
      {field, :desc} -> "-" <> Atom.to_string(field)
      {field, :asc} -> Atom.to_string(field)
      field when is_atom(field) -> Atom.to_string(field)
    end)
  end

  defp next_sort_direction(%Query{sort: sort}, field, requested) do
    cond do
      requested in ["asc", "desc"] ->
        String.to_atom(requested)

      Enum.any?(sort, &match?({^field, :asc}, &1)) or
          Enum.any?(sort, &(&1 == String.to_existing_atom(field))) ->
        :desc

      true ->
        :asc
    end
  rescue
    _ -> :asc
  end

  defp sort_param(field, :desc), do: "-" <> field
  defp sort_param(field, _direction), do: field

  defp blank_query_value?(nil), do: true
  defp blank_query_value?(""), do: true
  defp blank_query_value?(%{}), do: true

  defp blank_query_value?(value) when is_map(value),
    do: Enum.all?(value, fn {_k, v} -> blank_query_value?(v) end)

  defp blank_query_value?(_value), do: false

  defp refresh_socket(owner, socket, params) do
    if binding = refresh_binding_name(params) do
      refresh_single_binding(owner, socket, binding)
    else
      refresh_view(owner, socket, params)
    end
  end

  defp refresh_view(owner, socket, params) do
    ui = socket.assigns.ash_sdui_ui
    mode = socket.assigns.ash_sdui_mode
    opts = socket.assigns.ash_sdui_opts
    session = socket.assigns[:ash_sdui_session] || %{}
    current_params = socket.assigns[:ash_sdui_params] || %{}
    merged_params = Map.merge(current_params, params)

    case refresh_resource(owner, ui, mode, opts, merged_params, session, socket) do
      {:ok, refreshed} ->
        refreshed
        |> put_flash(:info, refresh_message(params))
        |> update_runtime_state(fn state ->
          %{
            state
            | refresh: Map.put(state.refresh || %{}, :last_refreshed_at, DateTime.utc_now())
          }
        end)

      {:error, _reason} ->
        put_flash(socket, :error, "Could not refresh view.")
    end
  end

  defp dispatch_intent(owner, %{"intent" => intent_name} = params, socket) do
    with {:ok, intent} <- lookup_intent(socket.assigns.ash_sdui_view, intent_name),
         {:ok, command} <- Intent.command(intent, params, intent_runtime(socket, params)) do
      apply_intent_command(owner, socket, intent, command)
    else
      {:error, _reason} ->
        put_flash(socket, :error, "Intent could not be executed.")
    end
  end

  defp dispatch_intent(_owner, _params, socket), do: socket

  defp apply_intent_command(_owner, socket, _intent, %{type: :navigate, meta: %{to: to}}) do
    push_navigate(socket, to: to)
  end

  defp apply_intent_command(_owner, socket, _intent, %{type: :patch, meta: %{to: to}}) do
    push_patch(socket, to: to)
  end

  defp apply_intent_command(owner, socket, _intent, %{type: :refresh, meta: meta}) do
    refresh_socket(owner, socket, refresh_params(meta))
  end

  defp apply_intent_command(_owner, socket, _intent, %{
         type: :select,
         meta: %{operation: operation},
         payload: payload
       }) do
    selection_params =
      payload
      |> Map.take(["id", :id])
      |> Map.put_new("operation", normalize_selection_operation(operation))

    update_selection(socket, selection_params)
  end

  defp apply_intent_command(_owner, socket, _intent, %{type: :workflow, meta: %{event: event}}) do
    update_workflow(socket, %{"event" => to_string(event)})
  end

  defp apply_intent_command(_owner, socket, _intent, %{
         type: :event,
         meta: %{event: event},
         payload: payload
       }) do
    socket
    |> put_flash(:info, "Triggered #{event}.")
    |> update_runtime_state(fn state ->
      %{state | assigns: Map.put(state.assigns || %{}, :last_event, payload)}
    end)
  end

  defp apply_intent_command(_owner, socket, _intent, %{type: :ash_action}) do
    put_flash(socket, :info, "Use the generated form flow to run this action.")
  end

  defp apply_intent_command(_owner, socket, _intent, _command), do: socket

  defp lookup_intent(%View{intents: intents}, intent_name) do
    intent_atom =
      cond do
        is_atom(intent_name) -> intent_name
        is_binary(intent_name) -> String.to_existing_atom(intent_name)
        true -> intent_name
      end

    case Enum.find(intents, &(&1.name == intent_atom)) do
      nil -> {:error, :intent_not_found}
      intent -> {:ok, intent}
    end
  rescue
    ArgumentError -> {:error, :invalid_intent}
  end

  defp intent_runtime(socket, params) do
    %{
      actor: socket.assigns.ash_sdui_context.actor,
      tenant: socket.assigns.ash_sdui_context.tenant,
      domain: root_domain(socket.assigns.ash_sdui_resource, socket.assigns.ash_sdui_opts),
      resource: socket.assigns.ash_sdui_resource,
      record: socket.assigns[:subject],
      params: params
    }
  end

  defp refresh_params(%{binding: nil}), do: %{}
  defp refresh_params(%{binding: :view}), do: %{}

  defp refresh_params(%{binding: binding}) when is_atom(binding),
    do: %{"binding" => Atom.to_string(binding)}

  defp refresh_params(_meta), do: %{}

  defp update_selection(socket, params) do
    socket
    |> update_runtime_state(&RuntimeState.apply_selection(&1, params))
    |> maybe_assign_selected_records()
  end

  defp maybe_assign_selected_records(
         %{assigns: %{records: records, ash_sdui_state: state}} = socket
       )
       when is_list(records) do
    assign(socket, :selected_records, RuntimeState.selected_records(state, records))
  end

  defp maybe_assign_selected_records(socket), do: socket

  defp update_workflow(socket, params) do
    update_runtime_state(socket, &RuntimeState.apply_workflow(&1, params))
  end

  defp update_runtime_state(socket, fun) when is_function(fun, 1) do
    state = RuntimeState.update(socket.assigns.ash_sdui_state, fun)
    view = %{socket.assigns.ash_sdui_view | state: state}

    socket
    |> assign(:ash_sdui_state, state)
    |> assign(:ash_sdui_view, view)
  end

  defp normalize_selection_operation({mode, _opts}) when is_atom(mode), do: Atom.to_string(mode)
  defp normalize_selection_operation(mode) when is_atom(mode), do: Atom.to_string(mode)
  defp normalize_selection_operation(mode) when is_binary(mode), do: mode
  defp normalize_selection_operation(_mode), do: "toggle"

  defp apply_live_message(owner, socket, {:ash_sdui_poll, binding}) do
    {:ok, refresh_single_binding(owner, socket, binding)}
  end

  defp apply_live_message(_owner, socket, message) do
    case matching_live_binding(socket, message) do
      nil ->
        :ignore

      binding ->
        with {:ok, current} <- current_binding_value(socket, binding.name),
             {:ok, next, _meta} <- AshSDUI.Binding.apply_update(binding, current, message) do
          {:ok, update_binding_runtime(socket, binding, next)}
        end
    end
  end

  defp matching_live_binding(socket, message) do
    socket.assigns.ash_sdui_view.bindings
    |> Enum.find(&AshSDUI.Binding.subscription_match?(&1, message))
  end

  defp current_binding_value(socket, binding_name) do
    {:ok, Map.get(socket.assigns.ash_sdui_bindings || %{}, binding_name)}
  end

  defp refresh_single_binding(owner, socket, binding_name) do
    view = socket.assigns.ash_sdui_view
    binding = Enum.find(view.bindings, &(&1.name == binding_name))

    if binding do
      case load_single_binding(
             binding,
             view,
             socket.assigns.ash_sdui_opts,
             socket.assigns.ash_sdui_params
           ) do
        {:ok, value} ->
          update_binding_runtime(socket, binding, value)
          |> maybe_schedule_poll(binding)

        {:error, _reason} ->
          put_flash(socket, :error, "Could not refresh #{binding_name}.")
      end
    else
      refresh_view(owner, socket, %{})
    end
  end

  defp load_single_binding(binding, view, opts, params) do
    load_opts =
      [
        actor: view.context.actor,
        tenant: view.context.tenant,
        domain: root_domain(view.resource, opts),
        record_id: params["id"] || params[:id],
        record: BindingSet.primary_record(view, current_bindings_for_load(view, opts, params))
      ]
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    case AshSDUI.Binding.load([binding], load_opts) do
      {:ok, values} when is_map(values) -> {:ok, Map.get(values, binding.name)}
      {:ok, _} -> {:error, :missing_binding_value}
      {:error, {_name, reason}} -> {:error, reason}
    end
  end

  defp current_bindings_for_load(view, opts, params) do
    case load_bindings(view, opts, params) do
      {:ok, bindings} -> bindings
      _ -> %{}
    end
  end

  defp update_binding_runtime(socket, binding, value) do
    bindings = Map.put(socket.assigns.ash_sdui_bindings || %{}, binding.name, value)
    view = enrich_view(socket.assigns.ash_sdui_view, bindings)

    socket
    |> assign(:ash_sdui_bindings, bindings)
    |> then(fn socket ->
      refreshed_state = RuntimeState.mark_binding_refreshed(view.state, binding.name)
      refreshed_view = %{view | state: refreshed_state}

      socket
      |> assign(:ash_sdui_state, refreshed_state)
      |> assign(:ash_sdui_view, refreshed_view)
      |> sync_runtime_data(refreshed_view, bindings)
      |> maybe_assign_layout(refreshed_view)
    end)
  end

  defp sync_runtime_data(socket, view, bindings) do
    case assign_data(
           socket,
           view,
           bindings,
           socket.assigns.ash_sdui_opts,
           socket.assigns.ash_sdui_params
         ) do
      {:ok, socket} -> socket
      {:error, _reason} -> socket
    end
  end

  defp subscription_specs(view, opts) do
    AshSDUI.Binding.subscription_specs(view.bindings,
      pubsub_server: Keyword.get(opts, :pubsub_server)
    )
  end

  defp register_subscriptions(socket, view, opts) do
    specs = subscription_specs(view, opts)

    if connected?(socket) do
      Enum.each(specs, &register_subscription(socket, &1))
    end

    assign(socket, :ash_sdui_subscription_specs, specs)
  end

  defp register_subscription(_socket, %{kind: :poll, binding: binding, interval: interval})
       when is_integer(interval) and interval > 0 do
    Process.send_after(self(), {:ash_sdui_poll, binding}, interval)
  end

  defp register_subscription(socket, %{kind: :pubsub, topic: topic} = spec)
       when not is_nil(topic) do
    if pubsub_server = Map.get(spec, :pubsub_server) || endpoint_pubsub_server(socket) do
      Phoenix.PubSub.subscribe(pubsub_server, topic)
    end
  end

  defp register_subscription(_socket, _spec), do: :ok

  defp maybe_schedule_poll(socket, %AshSDUI.Binding{
         subscription: %{kind: :poll, interval: interval},
         name: name
       })
       when is_integer(interval) and interval > 0 do
    Process.send_after(self(), {:ash_sdui_poll, name}, interval)
    socket
  end

  defp maybe_schedule_poll(socket, _binding), do: socket

  defp endpoint_pubsub_server(socket) do
    endpoint = socket.endpoint

    cond do
      is_nil(endpoint) -> nil
      function_exported?(endpoint, :config, 1) -> endpoint.config(:pubsub_server)
      true -> nil
    end
  rescue
    _ -> nil
  end

  defp refresh_binding_name(%{"binding" => binding}) when is_binary(binding) do
    String.to_existing_atom(binding)
  rescue
    ArgumentError -> nil
  end

  defp refresh_binding_name(%{binding: binding}) when is_atom(binding), do: binding
  defp refresh_binding_name(_params), do: nil

  defp refresh_message(%{"binding" => binding}), do: "Refreshed #{binding}."
  defp refresh_message(_params), do: "Refreshed view."
end
