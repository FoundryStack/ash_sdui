defmodule SduiDemoWeb.Components.ResourceActions do
  @moduledoc false

  use Phoenix.Component

  attr(:resource, :atom, required: true)
  attr(:subject, :any, default: nil)
  attr(:actions, :list, default: nil)
  attr(:overrides, :map, default: %{})
  attr(:placement, :atom, default: nil)
  attr(:class, :string, default: nil)

  def render(assigns) do
    intents =
      assigns.actions || AshSDUI.Resource.Info.ui_intents(assigns.resource)

    intents =
      if assigns.actions || map_size(assigns.overrides) == 0 do
        intents
      else
        Enum.filter(intents, &Map.has_key?(assigns.overrides, &1.name))
      end
      |> Enum.map(&AshSDUI.Intent.resolve(&1, assigns.resource))

    overrides =
      assigns.overrides
      |> Enum.into(%{})
      |> Map.new(fn {name, override} ->
        {name, normalize_override(override)}
      end)

    assigns =
      assigns
      |> assign(:ui, assigns.resource)
      |> assign(:intents, intents)
      |> assign(:overrides, overrides)

    AshSDUI.Components.IntentBar.render(assigns)
  end

  defp normalize_override(override) when is_list(override),
    do: override |> Enum.into(%{}) |> normalize_override()

  defp normalize_override(override) when is_map(override) do
    Map.put_new_lazy(override, :target, fn ->
      case override[:kind] do
        :link -> {:navigate, override[:to]}
        :patch -> {:patch, override[:to]}
        :event -> {:event, override[:event]}
        :submit -> {:ash_action, override[:event] || override[:name]}
        _ -> nil
      end
    end)
  end

  defp normalize_override(_override), do: %{}
end
