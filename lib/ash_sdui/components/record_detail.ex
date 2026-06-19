defmodule AshSDUI.Components.RecordDetail do
  @moduledoc """
  DaisyUI-backed generated detail view for a single record.
  """

  use Phoenix.Component

  AshSDUI.Registry.register("AshSDUI.RecordDetail@v1", __MODULE__, %{
    fragment: "",
    subject_types: []
  })

  def __ash_sdui_component_name__, do: "AshSDUI.RecordDetail@v1"
  def __ash_sdui_fragment__, do: ""
  def __ash_sdui_subject_types__, do: []

  attr(:subject, :any, required: true)
  attr(:fields, :list, required: true)
  attr(:bindings, :map, default: %{})
  attr(:class, :string, default: nil)

  def render(assigns) do
    ~H"""
    <dl class={["grid grid-cols-1 gap-4 sm:grid-cols-2", @class]} data-testid="record-detail">
      <%= for field <- @fields do %>
        <div class="rounded-box border border-base-300 bg-base-100 p-4">
          <dt class="text-sm font-medium text-base-content/60">{field.label}</dt>
          <dd class="mt-1 text-base">
            <AshSDUI.Components.FieldValue.render
              subject={@subject}
              field={field}
              bindings={@bindings}
            />
          </dd>
        </div>
      <% end %>
    </dl>
    """
  end
end
