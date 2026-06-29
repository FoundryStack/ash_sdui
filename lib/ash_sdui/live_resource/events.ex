defmodule AshSDUI.LiveResource.Events do
  @moduledoc false

  import Phoenix.LiveView

  alias AshSDUI.LiveResource.IntentDispatch
  alias AshSDUI.LiveResource.QueryPatch
  alias AshSDUI.LiveResource.Runtime
  alias AshSDUI.Runtime.State, as: RuntimeState
  alias AshSDUI.Query

  def handle(_owner, "validate", params, socket) do
    form_name = Runtime.form_name(socket.assigns.ash_sdui_resource)
    form_params = Map.get(params, form_name, %{})
    form = ash_phoenix_form!().validate(socket.assigns.form.source, form_params)
    {:noreply, Phoenix.Component.assign(socket, :form, Phoenix.Component.to_form(form))}
  end

  def handle(_owner, "nested_add_form", %{"path" => path}, socket) do
    form = ash_phoenix_form!().add_form(socket.assigns.form.source, path)
    {:noreply, Phoenix.Component.assign(socket, :form, Phoenix.Component.to_form(form))}
  end

  def handle(_owner, "nested_remove_form", %{"path" => path}, socket) do
    form = ash_phoenix_form!().remove_form(socket.assigns.form.source, path)
    {:noreply, Phoenix.Component.assign(socket, :form, Phoenix.Component.to_form(form))}
  end

  def handle(_owner, "nested_sort_form", %{"path" => path, "direction" => direction}, socket) do
    instruction =
      case direction do
        "decrement" -> :decrement
        _ -> :increment
      end

    form = ash_phoenix_form!().sort_forms(socket.assigns.form.source, path, instruction)
    {:noreply, Phoenix.Component.assign(socket, :form, Phoenix.Component.to_form(form))}
  end

  def handle(_owner, "query", params, %{assigns: %{ash_sdui_view: view}} = socket) do
    {:noreply, QueryPatch.patch_query(socket, Query.update(view.state.query, :params, params))}
  end

  def handle(_owner, "sort", %{"field" => field} = params, socket) do
    query = socket.assigns.ash_sdui_view.state.query
    direction = next_sort_direction(query, field, Map.get(params, "direction"))

    {:noreply,
     QueryPatch.patch_query(
       socket,
       Query.update(query, :sort, %{"sort" => sort_param(field, direction)})
     )}
  end

  def handle(_owner, "paginate", %{"offset" => offset}, socket) do
    query = socket.assigns.ash_sdui_view.state.query

    {:noreply,
     QueryPatch.patch_query(socket, Query.update(query, :paginate, %{"offset" => offset}))}
  end

  def handle(_owner, "reset_query", _params, socket) do
    query = socket.assigns.ash_sdui_view.state.query
    {:noreply, QueryPatch.patch_query(socket, Query.update(query, :reset, %{}))}
  end

  def handle(owner, "refresh", params, socket) do
    {:noreply, Runtime.refresh_socket(owner, socket, params)}
  end

  def handle(_owner, "select", params, socket) do
    {:noreply, Runtime.update_selection(socket, params)}
  end

  def handle(_owner, "workflow", params, socket) do
    {:noreply, Runtime.update_workflow(socket, params)}
  end

  def handle(owner, "intent", params, socket) do
    {:noreply, IntentDispatch.dispatch(owner, params, socket)}
  end

  def handle(owner, "save", params, socket) do
    form_name = Runtime.form_name(socket.assigns.ash_sdui_resource)
    socket =
      update_runtime_state(socket, fn state ->
        RuntimeState.begin_operation(state, :save, %{kind: :form})
      end)

    form_params =
      owner.ash_sdui_transform_form_params(
        socket.assigns.ash_sdui_mode,
        Map.get(params, form_name, %{}),
        socket
      )

    case ash_phoenix_form!().submit(socket.assigns.form.source, params: form_params) do
      {:ok, record} ->
        socket =
          owner.ash_sdui_after_save(record, socket)
          |> update_runtime_state(fn state -> RuntimeState.complete_operation(state, :save) end)

        {:noreply, socket}

      {:error, form} ->
        socket =
          socket
          |> update_runtime_state(fn state ->
            RuntimeState.rollback_operation(state, :save, %{reason: :validation_error})
          end)
          |> Phoenix.Component.assign(:form, Phoenix.Component.to_form(form))

        {:noreply, socket}
    end
  end

  def handle(_owner, "delete", %{"id" => id}, socket) do
    resource = socket.assigns.ash_sdui_resource
    view = socket.assigns.ash_sdui_view

    socket =
      update_runtime_state(socket, fn state ->
        RuntimeState.begin_operation(state, :delete, %{kind: :resource, target: resource, payload: %{id: id}})
      end)

    with {:ok, record} <-
           Ash.get(
             resource,
             id,
             Runtime.ash_opts(resource, view.context, socket.assigns.ash_sdui_opts)
           ),
         :ok <- Ash.destroy(record) do
      socket =
        socket
        |> put_flash(:info, "Deleted.")
        |> reload_index()
        |> update_runtime_state(fn state -> RuntimeState.complete_operation(state, :delete) end)

      {:noreply, socket}
    else
      reason ->
        socket =
          socket
          |> update_runtime_state(fn state ->
            RuntimeState.rollback_operation(state, :delete, %{reason: reason})
          end)
          |> put_flash(:error, "Could not delete record.")

        {:noreply, socket}
    end
  end

  def handle(_owner, _event, _params, socket), do: {:noreply, socket}

  defp reload_index(
         %{assigns: %{ash_sdui_mode: :index, ash_sdui_view: view, ash_sdui_opts: opts}} = socket
       ) do
    params = socket.assigns[:ash_sdui_params] || %{}

    case Runtime.load_bindings(view, opts, params) do
      {:ok, bindings} ->
        runtime_view = Runtime.enrich_view(view, bindings)

        socket
        |> Phoenix.Component.assign(:ash_sdui_bindings, bindings)
        |> Phoenix.Component.assign(:ash_sdui_state, runtime_view.state)
        |> Phoenix.Component.assign(:ash_sdui_view, runtime_view)
        |> Runtime.sync_socket(
          nil,
          socket.assigns.ash_sdui_mode,
          params,
          runtime_view,
          bindings,
          opts
        )
        |> case do
          {:ok, synced} -> synced
          {:error, _reason} -> socket
        end

      {:error, _reason} ->
        socket
    end
  end

  defp reload_index(socket), do: socket

  defp update_runtime_state(socket, fun) when is_function(fun, 1) do
    state = RuntimeState.update(socket.assigns.ash_sdui_state, fun)
    view = %{socket.assigns.ash_sdui_view | state: state}

    socket
    |> Phoenix.Component.assign(:ash_sdui_state, state)
    |> Phoenix.Component.assign(:ash_sdui_view, view)
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

  defp ash_phoenix_form! do
    module = Module.concat([AshPhoenix, Form])

    if Code.ensure_loaded?(module) do
      module
    else
      raise "AshSDUI.LiveResource form views require ash_phoenix"
    end
  end
end
