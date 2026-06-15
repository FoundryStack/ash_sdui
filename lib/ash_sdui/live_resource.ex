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
  alias AshSDUI.Query
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
    assigns = assign(assigns, :reason, inspect(reason))

    ~H"""
    <div class="alert alert-error">{@reason}</div>
    """
  end

  def render_resource(%{__sdui_tree__: tree} = assigns) when not is_nil(tree) do
    ~H"""
      <AshSDUI.Components.SDUIRoot.render
        tree={@__sdui_tree__}
        context={@ash_sdui_view.context}
        domain={root_domain(@ash_sdui_resource, @ash_sdui_opts)}
      />
    """
  end

  def render_resource(%{ash_sdui_mode: mode} = assigns) when mode in [:new, :edit] do
    assigns = assign(assigns, :content_class, recipe_class(assigns.ash_sdui_view, :content))

    ~H"""
    <div class="space-y-6">
      <AshSDUI.Components.RecordForm.render
        form={@form}
        ui={@ash_sdui_ui}
        view={@ash_sdui_view}
        action={@ash_sdui_view.action}
        fields={@ash_sdui_view.fields}
        bindings={@ash_sdui_bindings}
        state={@ash_sdui_state}
        context={@ash_sdui_context}
        class={@content_class}
      >
        <:footer>
          <div class="flex justify-end">
            <button type="submit" class="btn btn-primary">Save</button>
          </div>
        </:footer>
      </AshSDUI.Components.RecordForm.render>
    </div>
    """
  end

  def render_resource(%{ash_sdui_mode: :show} = assigns) do
    assigns =
      assigns
      |> assign(:toolbar_hidden?, recipe_hidden?(assigns.ash_sdui_view, :toolbar))
      |> assign(:toolbar_class, recipe_class(assigns.ash_sdui_view, :toolbar))
      |> assign(:content_class, recipe_class(assigns.ash_sdui_view, :content))

    ~H"""
    <div class="space-y-6">
      <AshSDUI.Components.IntentBar.render
        :if={!@toolbar_hidden?}
        ui={@ash_sdui_ui}
        view={@ash_sdui_view}
        subject={@subject}
        intents={@ash_sdui_view.intents}
        bindings={@ash_sdui_bindings}
        state={@ash_sdui_state}
        context={@ash_sdui_context}
        placement={:toolbar}
        class={@toolbar_class}
      />
      <AshSDUI.Components.RecordDetail.render
        subject={@subject}
        fields={@ash_sdui_view.fields}
        bindings={@ash_sdui_bindings}
        class={@content_class}
      />
    </div>
    """
  end

  def render_resource(assigns) do
    assigns =
      assigns
      |> assign(:toolbar_hidden?, recipe_hidden?(assigns.ash_sdui_view, :toolbar))
      |> assign(:toolbar_class, recipe_class(assigns.ash_sdui_view, :toolbar))
      |> assign(:content_class, recipe_class(assigns.ash_sdui_view, :content))

    ~H"""
    <div class="space-y-6">
      <AshSDUI.Components.IntentBar.render
        :if={!@toolbar_hidden?}
        ui={@ash_sdui_ui}
        view={@ash_sdui_view}
        intents={@ash_sdui_view.intents}
        bindings={@ash_sdui_bindings}
        state={@ash_sdui_state}
        context={@ash_sdui_context}
        placement={:toolbar}
        class={@toolbar_class}
      />
      <AshSDUI.Components.RecordList.render
        records={@records}
        fields={@ash_sdui_view.fields}
        intents={@ash_sdui_view.intents}
        ui={@ash_sdui_ui}
        view={@ash_sdui_view}
        bindings={@ash_sdui_bindings}
        state={@ash_sdui_state}
        context={@ash_sdui_context}
        empty_title={@ash_sdui_view.assigns[:empty_state] || "No records"}
        empty_body={@ash_sdui_view.assigns[:empty_state_body]}
        class={@content_class}
      />
    </div>
    """
  end

  def default_after_save(socket, record), do: after_save(socket, record)

  defp assign_data(socket, %View{mode: :index} = view, bindings, _opts, _params) do
    records = primary_collection_value(view, bindings) || []
    {:ok, assign(socket, :records, records)}
  end

  defp assign_data(socket, %View{mode: :show} = view, bindings, _opts, _params) do
    case primary_record_value(view, bindings) do
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
      |> maybe_put_layout_opt(:records, socket.assigns[:records])
      |> maybe_put_layout_opt(:subject, socket.assigns[:subject])
      |> maybe_put_layout_opt(:form, socket.assigns[:form])

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
        |> assign(:records, primary_collection_value(view, bindings) || [])

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
      case primary_record_value(view, bindings) do
        nil ->
          {:ok, bindings}

        record ->
          AshSDUI.Binding.load(view.bindings, Keyword.put(base_opts, :record, record))
      end
    end
  end

  defp resolve_edit_subject(view, bindings, opts, id) do
    case primary_record_value(view, bindings) do
      nil -> Ash.get(view.resource, id, ash_opts(view.resource, view.context, opts))
      subject -> {:ok, subject}
    end
  end

  defp primary_collection_value(view, bindings) do
    binding_name =
      view.bindings
      |> Enum.find(& &1.many?)
      |> case do
        nil -> nil
        binding -> binding.name
      end

    binding_name && Map.get(bindings, binding_name)
  end

  defp primary_record_value(view, bindings) do
    binding_name =
      view.bindings
      |> Enum.find(&(not &1.many?))
      |> case do
        nil -> nil
        binding -> binding.name
      end

    binding_name && Map.get(bindings, binding_name)
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

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp maybe_put_layout_opt(opts, _key, nil), do: opts
  defp maybe_put_layout_opt(opts, key, value), do: Keyword.put(opts, key, value)

  defp recipe_hidden?(view, section) do
    view.assigns
    |> Map.get(:recipe_overrides, %{})
    |> Map.get(section, %{})
    |> Map.get(:skip?, false)
  end

  defp recipe_class(view, section) do
    view.assigns
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
        primary_collection: primary_collection_value(view, bindings),
        primary_record: primary_record_value(view, bindings)
      })

    %{view | state: %{state | assigns: state_assigns}}
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
    |> maybe_put_map("search", query.search)
    |> maybe_put_map("limit", query.limit)
    |> maybe_put_map("offset", query.offset)
    |> maybe_put_map("sort", sort_query_param(query.sort))
    |> maybe_put_map("filters", stringify_keys(query.filters))
  end

  defp maybe_put_map(map, _key, nil), do: map
  defp maybe_put_map(map, _key, ""), do: map
  defp maybe_put_map(map, _key, value) when value == %{}, do: map
  defp maybe_put_map(map, key, value), do: Map.put(map, key, value)

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
end
