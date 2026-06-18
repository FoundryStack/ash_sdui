defmodule AshSDUI.Components.MetricGrid do
  @moduledoc """
  Generic metrics panel for small refreshable dashboards.
  """

  use Phoenix.Component

  AshSDUI.Registry.register("AshSDUI.MetricGrid@v1", __MODULE__, %{
    fragment: "",
    subject_types: []
  })

  def __ash_sdui_component_name__, do: "AshSDUI.MetricGrid@v1"
  def __ash_sdui_fragment__, do: ""
  def __ash_sdui_subject_types__, do: []

  attr(:metrics, :list, default: nil)
  attr(:bound_value, :any, default: nil)
  attr(:class, :string, default: nil)

  def render(assigns) do
    assigns = assign(assigns, :metrics, assigns.metrics || List.wrap(assigns.bound_value))

    ~H"""
    <div class={["grid gap-4 sm:grid-cols-2 xl:grid-cols-4", @class]} data-testid="metric-grid">
      <article
        :for={metric <- @metrics}
        class="rounded-box border border-base-300 bg-base-100 p-4 shadow-sm"
      >
        <p class="text-sm uppercase tracking-[0.2em] text-base-content/55">{metric.label}</p>
        <p class="mt-3 text-3xl font-semibold">{metric.value}</p>
        <p :if={Map.get(metric, :hint)} class="mt-2 text-sm text-base-content/65">{metric.hint}</p>
      </article>
    </div>
    """
  end
end
