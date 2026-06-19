defmodule AshSDUI.Components.StatusBadge do
  @moduledoc """
  Generic status badge with a small set of semantic variants.
  """

  use Phoenix.Component

  AshSDUI.Registry.register("AshSDUI.StatusBadge@v1", __MODULE__, %{
    fragment: "",
    subject_types: []
  })

  def __ash_sdui_component_name__, do: "AshSDUI.StatusBadge@v1"
  def __ash_sdui_fragment__, do: ""
  def __ash_sdui_subject_types__, do: []

  attr(:status, :string, default: nil)
  attr(:variant, :atom, default: nil)
  attr(:bound_value, :any, default: nil)
  attr(:state_slice, :any, default: nil)
  attr(:class, :string, default: nil)

  def render(assigns) do
    status =
      assigns.status || extract_status(assigns.state_slice) || extract_status(assigns.bound_value)

    variant = assigns.variant || infer_variant(status)

    assigns =
      assigns
      |> assign(:status, to_string(status || "unknown"))
      |> assign(:variant, variant)

    ~H"""
    <span class={["badge badge-outline font-medium uppercase tracking-[0.16em]", variant_class(@variant), @class]} data-testid="status-badge">
      {@status}
    </span>
    """
  end

  defp variant_class(:success), do: "badge-success"
  defp variant_class(:warning), do: "badge-warning"
  defp variant_class(:error), do: "badge-error"
  defp variant_class(:info), do: "badge-info"
  defp variant_class(_), do: "badge-neutral"

  defp extract_status(%{state: state}) when not is_nil(state), do: state
  defp extract_status(%{"state" => state}) when not is_nil(state), do: state
  defp extract_status(%{status: status}) when not is_nil(status), do: status
  defp extract_status(%{"status" => status}) when not is_nil(status), do: status
  defp extract_status(value) when is_binary(value), do: value
  defp extract_status(value) when is_atom(value), do: Atom.to_string(value)
  defp extract_status(_value), do: nil

  defp infer_variant(status) when status in ["approved", "active", "ready", "success"],
    do: :success

  defp infer_variant(status) when status in ["review", "pending", "warning"], do: :warning
  defp infer_variant(status) when status in ["paused", "info"], do: :info
  defp infer_variant(status) when status in ["error", "failed"], do: :error
  defp infer_variant(_status), do: :neutral
end
