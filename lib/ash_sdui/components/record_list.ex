defmodule AshSDUI.Components.RecordList do
  @moduledoc """
  DaisyUI-backed generated list view for Ash records.
  """

  use Phoenix.Component

  AshSDUI.Registry.register("AshSDUI.RecordList@v1", __MODULE__, %{
    fragment: "",
    subject_types: []
  })

  def __ash_sdui_component_name__, do: "AshSDUI.RecordList@v1"
  def __ash_sdui_fragment__, do: ""
  def __ash_sdui_subject_types__, do: []

  attr(:records, :list, default: [])
  attr(:fields, :list, required: true)
  attr(:intents, :list, default: [])
  attr(:ui, :atom, default: nil)
  attr(:view, :any, default: nil)
  attr(:bindings, :map, default: %{})
  attr(:state, :any, default: nil)
  attr(:context, :any, default: nil)
  attr(:empty_title, :string, default: "No records")
  attr(:empty_body, :string, default: nil)
  attr(:class, :string, default: nil)

  def render(assigns) do
    query = assigns[:state] && assigns.state.query
    assigns = assign(assigns, :query, query)

    ~H"""
    <div class={["space-y-4", @class]}>
      <.query_controls :if={@query} query={@query} />

      <%= if Enum.empty?(@records) do %>
        <AshSDUI.Components.EmptyState.render title={@empty_title} body={@empty_body} />
      <% else %>
        <div class="overflow-x-auto rounded-box border border-base-300 bg-base-100">
        <table class="table">
          <thead>
            <tr>
              <%= for field <- @fields do %>
                <th>
                  <%= if sortable?(field, @query) do %>
                    <button
                      type="button"
                      phx-click="sort"
                      phx-value-field={field.name}
                      class="inline-flex items-center gap-1 font-semibold"
                    >
                      <span>{field.label}</span>
                      <span class="text-xs text-base-content/45">{sort_indicator(@query, field.name)}</span>
                    </button>
                  <% else %>
                    {field.label}
                  <% end %>
                </th>
              <% end %>
              <th :if={@intents != []}></th>
            </tr>
          </thead>
          <tbody>
            <%= for record <- @records do %>
              <tr>
                <%= for field <- @fields do %>
                  <td>
                    <AshSDUI.Components.FieldValue.render
                      subject={record}
                      field={field}
                      bindings={@bindings}
                    />
                  </td>
                <% end %>
                <td :if={@intents != []} class="text-right">
                  <AshSDUI.Components.IntentBar.render
                    ui={@ui}
                    view={@view}
                    subject={record}
                    intents={@intents}
                    bindings={@bindings}
                    state={@state}
                    context={@context}
                    placement={:row}
                  />
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
        </div>

        <.pagination :if={show_pagination?(@query, @records)} query={@query} record_count={length(@records)} />
      <% end %>
    </div>
    """
  end

  attr(:query, :any, required: true)

  defp query_controls(assigns) do
    ~H"""
    <form phx-change="query" class="rounded-box border border-base-300 bg-base-100 p-4">
      <div class="grid gap-3 md:grid-cols-[minmax(0,2fr)_repeat(auto-fit,minmax(10rem,1fr))_auto] md:items-end">
        <label :if={@query.search_fields != []} class="form-control">
          <span class="label-text text-sm font-medium">Search</span>
          <input
            type="text"
            name="search"
            value={@query.search || ""}
            placeholder="Search"
            class="input input-bordered w-full"
          />
        </label>

        <label :for={field <- @query.filter_fields} class="form-control">
          <span class="label-text text-sm font-medium">{labelize(field)}</span>
          <input
            type="text"
            name={"filters[#{field}]"}
            value={Map.get(@query.filters, field, "")}
            class="input input-bordered w-full"
          />
        </label>

        <div class="flex items-center gap-2 md:justify-end">
          <button type="button" phx-click="reset_query" class="btn btn-ghost btn-sm">Reset</button>
        </div>
      </div>
    </form>
    """
  end

  attr(:query, :any, required: true)
  attr(:record_count, :integer, required: true)

  defp pagination(assigns) do
    ~H"""
    <div class="flex items-center justify-between text-sm text-base-content/70">
      <span>
        Showing {pagination_range(@query, @record_count)}
      </span>
      <div class="flex items-center gap-2">
        <button
          type="button"
          phx-click="paginate"
          phx-value-offset={max((@query.offset || 0) - (@query.limit || 0), 0)}
          class="btn btn-ghost btn-sm"
          disabled={(@query.offset || 0) <= 0}
        >
          Previous
        </button>
        <button
          type="button"
          phx-click="paginate"
          phx-value-offset={(@query.offset || 0) + (@query.limit || 0)}
          class="btn btn-ghost btn-sm"
          disabled={@record_count < (@query.limit || 0)}
        >
          Next
        </button>
      </div>
    </div>
    """
  end

  defp sortable?(field, nil), do: Map.get(field, :sortable?, false)

  defp sortable?(field, query) do
    Map.get(field, :sortable?, false) or Map.get(field, :name) in (query.sort_fields || [])
  end

  defp sort_indicator(nil, _field), do: ""
  defp sort_indicator(%{sort: [{field, :desc} | _]}, field), do: "DESC"
  defp sort_indicator(%{sort: [{field, _} | _]}, field), do: "ASC"
  defp sort_indicator(_, _field), do: ""

  defp show_pagination?(nil, _records), do: false
  defp show_pagination?(%{limit: nil, default_limit: nil}, _records), do: false
  defp show_pagination?(_, _records), do: true

  defp pagination_range(query, record_count) do
    offset = query.offset || 0

    case record_count do
      0 -> "0 records"
      count -> "#{offset + 1}-#{offset + count}"
    end
  end

  defp labelize(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
