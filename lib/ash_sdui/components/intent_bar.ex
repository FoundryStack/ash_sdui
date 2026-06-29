defmodule AshSDUI.Components.IntentBar do
  @moduledoc """
  DaisyUI-backed intent bar for `ui_intent` metadata.
  """

  use Phoenix.Component

  AshSDUI.Registry.register("AshSDUI.IntentBar@v1", __MODULE__, %{
    fragment: "",
    subject_types: []
  })

  def __ash_sdui_component_name__, do: "AshSDUI.IntentBar@v1"
  def __ash_sdui_fragment__, do: ""
  def __ash_sdui_subject_types__, do: []

  alias AshSDUI.Resource.Info
  alias AshSDUI.Intent

  attr(:ui, :atom, required: true)
  attr(:view, :any, default: nil)
  attr(:subject, :any, default: nil)
  attr(:intents, :list, default: nil)
  attr(:bindings, :map, default: %{})
  attr(:state, :any, default: nil)
  attr(:context, :any, default: nil)
  attr(:overrides, :map, default: %{})
  attr(:placement, :atom, default: nil)
  attr(:class, :string, default: nil)

  def render(assigns) do
    intents =
      assigns.intents ||
        assigns.ui
        |> Info.ui_intents()
        |> Enum.map(fn intent ->
          Map.put(intent, :resolved_label, Info.resolve_label(intent, assigns.ui))
        end)

    intents =
      if assigns.placement do
        Enum.filter(intents, &(&1.placement in [nil, assigns.placement]))
      else
        intents
      end
      |> Enum.filter(&visible?(&1, assigns))

    assigns = assign(assigns, :intents, intents)

    ~H"""
    <div class={["flex flex-wrap justify-end gap-2", @class]} data-testid="intent-bar">
      <%= for intent <- @intents do %>
        <.intent
          intent={intent}
          subject={@subject}
          state={@state}
          bindings={@bindings}
          override={Map.get(@overrides, intent.name, %{})}
        />
      <% end %>
    </div>
    """
  end

  attr(:intent, :any, required: true)
  attr(:subject, :any, default: nil)
  attr(:state, :any, default: nil)
  attr(:bindings, :map, default: %{})
  attr(:override, :map, default: %{})

  def intent(assigns) do
    label =
      Map.get(assigns.intent, :resolved_label) || Map.get(assigns.intent, :label) ||
        to_string(assigns.intent.name)

    assigns =
      assigns
      |> assign(
        :presentation,
        Intent.presentation(assigns.intent, assigns.subject,
          override: assigns.override,
          bindings: assigns.bindings,
          state: assigns.state
        )
      )
      |> assign(:kind, nil)
      |> assign(:label, label)
      |> assign(:enabled?, false)
      |> assign(:loading?, false)
      |> then(fn assigns ->
        assigns
        |> assign(:kind, assigns.presentation.kind)
        |> assign(:enabled?, assigns.presentation.enabled?)
        |> assign(:loading?, assigns.presentation.loading?)
      end)

    ~H"""
    <%= case @kind do %>
      <% :link -> %>
        <a
          href={@presentation.to}
          class={button_class(Map.get(@intent, :style), @override[:class], @loading?, @enabled?)}
          aria-disabled={to_string(not @enabled?)}
        >
          {@label}
        </a>
      <% :event -> %>
        <button
          type="button"
          phx-click={@presentation.event}
          phx-value-id={@override[:id] || (@subject && @subject.id)}
          phx-disable-with={loading_text(@intent, @label)}
          data-confirm={@presentation.confirm}
          aria-busy={@loading?}
          class={button_class(Map.get(@intent, :style), @override[:class], @loading?, @enabled?)}
          disabled={!@enabled?}
        >
          {@label}
        </button>
      <% :submit -> %>
        <button
          type="submit"
          phx-disable-with={loading_text(@intent, @label)}
          aria-busy={@loading?}
          class={button_class(Map.get(@intent, :style), @override[:class], @loading?, @enabled?)}
          disabled={!@enabled?}
        >
          {@label}
        </button>
      <% :intent -> %>
        <button
          type="button"
          phx-click="intent"
          phx-value-intent={@intent.name}
          phx-value-id={@override[:id] || (@subject && @subject.id)}
          phx-disable-with={loading_text(@intent, @label)}
          data-confirm={@presentation.confirm}
          aria-busy={@loading?}
          class={button_class(Map.get(@intent, :style), @override[:class], @loading?, @enabled?)}
          disabled={!@enabled?}
        >
          {@label}
        </button>
      <% _ -> %>
    <% end %>
    """
  end

  defp button_class(style, class, loading?, enabled?) do
    [
      "btn btn-sm",
      case style do
        :primary -> "btn-primary"
        :secondary -> "btn-ghost"
        :destructive -> "btn-error btn-outline"
        :info -> "btn-info btn-outline"
        _ -> "btn-ghost"
      end,
      loading? && "loading",
      !enabled? && "btn-disabled opacity-60 pointer-events-none",
      class
    ]
  end

  defp visible?(intent, %{bindings: bindings}) do
    case Map.get(intent, :visible_when) do
      nil -> true
      binding when is_atom(binding) -> not is_nil(Map.get(bindings, binding))
      _ -> true
    end
  end

  defp loading_text(%{style: :destructive}, _label), do: "Deleting..."
  defp loading_text(%{target: {:ash_action, _}}, _label), do: "Saving..."
  defp loading_text(%{target: {:event, _}}, label), do: "#{label}..."
  defp loading_text(%{target: {:refresh, _}}, _label), do: "Refreshing..."
  defp loading_text(%{target: {:select, _}}, _label), do: "Updating..."
  defp loading_text(%{target: {:workflow, _}}, _label), do: "Updating..."
  defp loading_text(_intent, label), do: "#{label}..."
end
