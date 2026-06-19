defmodule AshSDUI.LiveResource.Runtime do
  @moduledoc false

  import Phoenix.Component

  alias AshSDUI.Binding
  alias AshSDUI.Binding.Loader
  alias AshSDUI.Context
  alias AshSDUI.LiveResource.Subscriptions
  alias AshSDUI.Runtime.BindingSet
  alias AshSDUI.Runtime.Normalize
  alias AshSDUI.Runtime.State, as: RuntimeState
  alias AshSDUI.View

  @view_opt_keys [
    :recipe,
    :variant_resolvers,
    :field_overrides,
    :intent_overrides,
    :recipe_overrides,
    :assigns
  ]

  def mount(owner, ui, mode, opts, params, session, socket) do
    run(owner, ui, mode, opts, params, session, socket, include_ui?: true)
  end

  def refresh(owner, ui, mode, opts, params, session, socket) do
    run(owner, ui, mode, opts, params, session, socket, include_ui?: false)
  end

  def sync_socket(socket, owner, mode, params, %View{} = view, bindings, opts, sync_opts \\ []) do
    with {:ok, data_assigns} <- data_assigns(view, bindings, opts, params) do
      selected_records = BindingSet.selected_records(view.state, bindings, view)

      socket =
        socket
        |> assign(data_assigns)
        |> assign(:selected_records, selected_records)
        |> maybe_assign_layout(view, bindings, data_assigns)

      if Keyword.get(sync_opts, :load_hook_assigns?, false) do
        {:ok, assign_hook_assigns(socket, owner, mode, params)}
      else
        {:ok, socket}
      end
    end
  end

  def enrich_view(%View{} = view, bindings) do
    state = view.state || %View.State{}

    state_assigns =
      state.assigns
      |> Map.merge(%{
        bindings: bindings,
        primary_collection: BindingSet.primary_collection(view, bindings),
        primary_record: BindingSet.primary_record(view, bindings)
      })

    %{
      view
      | state: %{
          state
          | assigns: state_assigns,
            refresh: RuntimeState.refresh_snapshot(bindings, state)
        }
    }
  end

  def binding_load_context(%View{} = view, opts, params, bindings \\ nil) do
    Loader.new_context(
      actor: view.context.actor,
      tenant: view.context.tenant,
      domain: root_domain(view.resource, opts),
      record_id: params["id"] || params[:id],
      record: binding_record(view, bindings)
    )
  end

  def load_bindings(%View{mode: :new}, _opts, _params), do: {:ok, %{}}

  def load_bindings(%View{} = view, opts, params) do
    context = binding_load_context(view, opts, params, nil)

    with {:ok, bindings} <- Binding.load(view.bindings, context) do
      case BindingSet.primary_record(view, bindings) do
        nil ->
          {:ok, bindings}

        record ->
          view.bindings
          |> Binding.load(Map.put(context, :record, record))
      end
    end
  end

  def load_single_binding(binding, view, opts, params, bindings \\ nil) do
    context = binding_load_context(view, opts, params, bindings)

    case Binding.load([binding], context) do
      {:ok, values} when is_map(values) -> {:ok, Map.get(values, binding.name)}
      {:ok, _} -> {:error, :missing_binding_value}
      {:error, {_name, reason}} -> {:error, reason}
    end
  end

  def refresh_socket(owner, socket, params) do
    if binding = refresh_binding_name(params) do
      Subscriptions.refresh_single_binding(owner, socket, binding)
    else
      refresh_view(owner, socket, params)
    end
  end

  def update_selection(socket, params) do
    socket
    |> update_runtime_state(&RuntimeState.apply_selection(&1, params))
    |> assign(
      :selected_records,
      BindingSet.selected_records(
        socket.assigns.ash_sdui_state,
        socket.assigns.ash_sdui_bindings,
        socket.assigns.ash_sdui_view
      )
    )
  end

  def update_workflow(socket, params) do
    update_runtime_state(socket, &RuntimeState.apply_workflow(&1, params))
  end

  def update_binding_runtime(socket, binding, value) do
    bindings = Map.put(socket.assigns.ash_sdui_bindings || %{}, binding.name, value)
    view = enrich_view(socket.assigns.ash_sdui_view, bindings)
    state = RuntimeState.mark_binding_refreshed(view.state, binding.name)
    refreshed_view = %{view | state: state}

    socket
    |> assign(:ash_sdui_bindings, bindings)
    |> assign(:ash_sdui_state, state)
    |> assign(:ash_sdui_view, refreshed_view)
    |> sync_socket(
      nil,
      socket.assigns.ash_sdui_mode,
      socket.assigns.ash_sdui_params,
      refreshed_view,
      bindings,
      socket.assigns.ash_sdui_opts
    )
    |> case do
      {:ok, synced} -> synced
      {:error, _reason} -> socket
    end
  end

  def context_from(owner, opts, params, session, socket) do
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

  def ash_opts(resource, context, opts) do
    []
    |> Normalize.maybe_put_keyword(
      :domain,
      Keyword.get(opts, :domain) || resource_domain(resource)
    )
    |> Normalize.maybe_put_keyword(:actor, context.actor)
    |> Normalize.maybe_put_keyword(:tenant, context.tenant)
  end

  def root_domain(resource, opts) do
    Keyword.get(opts, :domain) || resource_domain(resource)
  end

  def form_name(resource) do
    resource |> Module.split() |> List.last() |> Macro.underscore()
  end

  def subscription_specs(view, opts) do
    Binding.subscription_specs(view.bindings, pubsub_server: Keyword.get(opts, :pubsub_server))
  end

  defp run(owner, ui, mode, opts, params, session, socket, run_opts) do
    context = context_from(owner, opts, params, session, socket)
    view_opts = build_view_opts(owner, mode, opts, params, session, socket, context)

    with {:ok, view} <- View.resolve(ui, mode, view_opts),
         {:ok, bindings} <- load_bindings(view, opts, params),
         runtime_view = enrich_view(view, bindings),
         {:ok, runtime_view} <- hydrate_form_fields(runtime_view, opts),
         {:ok, socket} <- sync_socket(socket, owner, mode, params, runtime_view, bindings, opts) do
      socket =
        socket
        |> assign_common(ui, mode, opts, session, params, runtime_view, bindings, run_opts)
        |> Subscriptions.register(runtime_view, opts)
        |> assign_hook_assigns(owner, mode, params)

      {:ok, socket}
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

  defp assign_common(socket, ui, mode, opts, session, params, runtime_view, bindings, run_opts) do
    socket
    |> assign(:ash_sdui_resource, runtime_view.resource)
    |> assign(:ash_sdui_bindings, bindings)
    |> assign(:ash_sdui_context, runtime_view.context)
    |> assign(:ash_sdui_state, runtime_view.state)
    |> assign(:ash_sdui_view, runtime_view)
    |> assign(:ash_sdui_mode, mode)
    |> assign(:ash_sdui_opts, opts)
    |> assign(:ash_sdui_session, session)
    |> assign(:ash_sdui_params, params)
    |> assign(:page_title, runtime_view.assigns[:title])
    |> maybe_assign_ui(ui, run_opts)
    |> assign_new(:ash_sdui_uri, fn -> nil end)
  end

  defp maybe_assign_ui(socket, ui, include_ui?: true), do: assign(socket, :ash_sdui_ui, ui)
  defp maybe_assign_ui(socket, _ui, _run_opts), do: socket

  defp build_view_opts(owner, mode, opts, params, session, socket, context) do
    runtime_view_opts = owner.ash_sdui_view_opts(mode, params, session, socket)

    opts
    |> Keyword.take(@view_opt_keys)
    |> Keyword.merge(runtime_view_opts)
    |> Keyword.put(:context, context)
    |> Keyword.put(:params, params)
  end

  defp data_assigns(%View{mode: :index} = view, bindings, _opts, _params) do
    {:ok,
     %{records: BindingSet.primary_collection(view, bindings) || [], subject: nil, form: nil}}
  end

  defp data_assigns(%View{mode: :show} = view, bindings, _opts, _params) do
    case BindingSet.primary_record(view, bindings) do
      nil -> {:error, :missing_subject}
      subject -> {:ok, %{records: nil, subject: subject, form: nil}}
    end
  end

  defp data_assigns(%View{mode: mode} = view, bindings, opts, params)
       when mode in [:new, :edit] do
    with {:ok, %{form: form, subject: subject}} <- build_form(view, bindings, opts, params) do
      {:ok, %{records: nil, subject: subject, form: Phoenix.Component.to_form(form)}}
    end
  end

  defp data_assigns(_view, _bindings, _opts, _params),
    do: {:ok, %{records: nil, subject: nil, form: nil}}

  defp maybe_assign_layout(
         socket,
         %View{assigns: %{layout: :sdui}} = view,
         bindings,
         data_assigns
       ) do
    layout_opts =
      []
      |> Keyword.put(:bindings, bindings)
      |> Keyword.put(:state, view.state)
      |> Keyword.put(:context, view.context)
      |> Normalize.maybe_put_keyword(:records, data_assigns.records)
      |> Normalize.maybe_put_keyword(:subject, data_assigns.subject)
      |> Normalize.maybe_put_keyword(:form, data_assigns.form)

    case View.to_layout(view, layout_opts) do
      {:ok, layout} -> assign(socket, :__sdui_tree__, AshSDUI.Layout.Builder.to_tree(layout))
      {:error, _reason} -> assign(socket, :__sdui_tree__, nil)
    end
  end

  defp maybe_assign_layout(socket, _view, _bindings, _data_assigns) do
    assign(socket, :__sdui_tree__, nil)
  end

  defp build_form(%View{mode: :new} = view, _bindings, opts, _params) do
    form =
      ash_phoenix_form!().for_create(
        view.resource,
        view.action,
        ash_opts(view.resource, view.context, opts) ++
          [
            as: form_name(view.resource),
            forms: generated_nested_forms_opts(view),
            prepare_params: &AshSDUI.Form.prepare_params(&1, view.fields)
          ]
      )

    {:ok, %{form: form, subject: nil}}
  rescue
    error -> {:error, error}
  end

  defp build_form(%View{mode: :edit} = view, bindings, opts, %{"id" => id}) do
    with {:ok, subject} <- resolve_edit_subject(view, bindings, opts, id) do
      params = AshSDUI.Form.initial_params(subject, view.fields)

      form =
        ash_phoenix_form!().for_update(
          subject,
          view.action,
          ash_opts(view.resource, view.context, opts) ++
            [
              as: form_name(view.resource),
              forms: generated_nested_forms_opts(view),
              params: params,
              prepare_params: &AshSDUI.Form.prepare_params(&1, view.fields)
            ]
        )

      {:ok, %{form: form, subject: subject}}
    end
  rescue
    error -> {:error, error}
  end

  defp resolve_edit_subject(view, bindings, opts, id) do
    case BindingSet.primary_record(view, bindings) do
      nil -> Ash.get(view.resource, id, ash_opts(view.resource, view.context, opts))
      subject -> {:ok, subject}
    end
    |> case do
      {:ok, subject} -> load_relationship_values(subject, view, opts)
      error -> error
    end
  end

  defp hydrate_form_fields(%View{mode: mode} = view, opts) when mode in [:new, :edit] do
    hydrated_fields =
      AshSDUI.Form.hydrate(
        view.ui,
        view.action,
        view.fields,
        domain: root_domain(view.resource, opts),
        actor: view.context.actor,
        tenant: view.context.tenant
      )

    {:ok, %{view | fields: hydrated_fields}}
  rescue
    error -> {:error, error}
  end

  defp hydrate_form_fields(view, _opts), do: {:ok, view}

  defp load_relationship_values(subject, view, opts) do
    loads =
      ((view.fields
        |> Enum.filter(&(&1.input_source == :argument && &1.relationship))
        |> Enum.map(& &1.relationship)) ++
         nested_relationship_loads(view.nested_forms))
      |> Enum.uniq()

    case loads do
      [] ->
        {:ok, subject}

      _ ->
        Ash.load(subject, loads, ash_opts(view.resource, view.context, opts))
    end
  end

  defp refresh_view(owner, socket, params) do
    ui = socket.assigns.ash_sdui_ui
    mode = socket.assigns.ash_sdui_mode
    opts = socket.assigns.ash_sdui_opts
    session = socket.assigns[:ash_sdui_session] || %{}
    current_params = socket.assigns[:ash_sdui_params] || %{}
    merged_params = Map.merge(current_params, params)

    case refresh(owner, ui, mode, opts, merged_params, session, socket) do
      {:ok, refreshed} ->
        refreshed
        |> maybe_put_flash(:info, refresh_message(params))
        |> update_runtime_state(fn state ->
          %{
            state
            | refresh: Map.put(state.refresh || %{}, :last_refreshed_at, DateTime.utc_now())
          }
        end)

      {:error, _reason} ->
        socket
        |> maybe_put_flash(:error, "Could not refresh view.")
    end
  end

  defp update_runtime_state(socket, fun) when is_function(fun, 1) do
    state = RuntimeState.update(socket.assigns.ash_sdui_state, fun)
    view = %{socket.assigns.ash_sdui_view | state: state}

    socket
    |> assign(:ash_sdui_state, state)
    |> assign(:ash_sdui_view, view)
  end

  defp binding_record(_view, nil), do: nil
  defp binding_record(view, bindings), do: BindingSet.primary_record(view, bindings)

  defp assign_hook_assigns(socket, owner, mode, params) do
    owner.ash_sdui_load_assigns(mode, params, socket)
    |> Enum.into(%{})
    |> then(&assign(socket, &1))
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

  defp maybe_put_flash(%{assigns: %{flash: _}} = socket, level, message),
    do: Phoenix.LiveView.put_flash(socket, level, message)

  defp maybe_put_flash(socket, _level, _message), do: socket

  defp resource_domain(resource) do
    Ash.Resource.Info.domain(resource)
  rescue
    _ -> nil
  end

  defp ash_phoenix_form! do
    module = Module.concat([AshPhoenix, Form])

    if Code.ensure_loaded?(module) do
      module
    else
      raise "AshSDUI.LiveResource form views require ash_phoenix"
    end
  end

  defp generated_nested_forms_opts(%View{nested_forms: []}), do: [auto?: false]
  defp generated_nested_forms_opts(%View{}), do: [auto?: true]

  defp nested_relationship_loads(nested_forms) do
    Enum.flat_map(nested_forms || [], fn nested_form ->
      [nested_form.relationship | nested_relationship_loads(nested_form.nested_forms)]
    end)
    |> Enum.reject(&(&1 in [nil, :_join]))
  end
end
