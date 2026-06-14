defmodule AshSDUI.Components.ResourceCollection do
  @moduledoc """
  DaisyUI-backed generated collection view for Ash resource records.
  """

  use Phoenix.Component

  attr(:records, :list, default: [])
  attr(:fields, :list, required: true)
  attr(:actions, :list, default: [])
  attr(:resource, :atom, default: nil)
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
              <th :if={@actions != []}></th>
            </tr>
          </thead>
          <tbody>
            <%= for record <- @records do %>
              <tr>
                <%= for field <- @fields do %>
                  <td>
                    <AshSDUI.Components.FieldValue.render subject={record} field={field} />
                  </td>
                <% end %>
                <td :if={@actions != []} class="text-right">
                  <AshSDUI.Components.ResourceActions.render
                    resource={@resource}
                    subject={record}
                    actions={@actions}
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
