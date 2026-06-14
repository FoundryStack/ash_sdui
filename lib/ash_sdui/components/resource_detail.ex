defmodule AshSDUI.Components.ResourceDetail do
  @moduledoc """
  DaisyUI-backed generated detail view for a single Ash resource record.
  """

  use Phoenix.Component

  attr(:subject, :any, required: true)
  attr(:fields, :list, required: true)
  attr(:class, :string, default: nil)

  def render(assigns) do
    ~H"""
    <dl class={["grid grid-cols-1 gap-4 sm:grid-cols-2", @class]} data-testid="resource-detail">
      <%= for field <- @fields do %>
        <div class="rounded-box border border-base-300 bg-base-100 p-4">
          <dt class="text-sm font-medium text-base-content/60">{field.label}</dt>
          <dd class="mt-1 text-base">
            <AshSDUI.Components.FieldValue.render subject={@subject} field={field} />
          </dd>
        </div>
      <% end %>
    </dl>
    """
  end
end
