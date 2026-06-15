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
    ~H"""
    <%= if Enum.empty?(@records) do %>
      <AshSDUI.Components.EmptyState.render title={@empty_title} body={@empty_body} />
    <% else %>
      <div class={["overflow-x-auto rounded-box border border-base-300 bg-base-100", @class]}>
        <table class="table">
          <thead>
            <tr>
              <%= for field <- @fields do %>
                <th>{field.label}</th>
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
    <% end %>
    """
  end
end
