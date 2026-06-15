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
        <.intent intent={intent} subject={@subject} override={Map.get(@overrides, intent.name, %{})} />
      <% end %>
    </div>
    """
  end

  attr(:intent, :any, required: true)
  attr(:subject, :any, default: nil)
  attr(:override, :map, default: %{})

  def intent(assigns) do
    label =
      Map.get(assigns.intent, :resolved_label) || Map.get(assigns.intent, :label) ||
        to_string(assigns.intent.name)

    assigns =
      assigns
      |> assign(:kind, target_kind(assigns.intent, assigns.override))
      |> assign(:label, label)

    ~H"""
    <%= case @kind do %>
      <% :link -> %>
        <a href={target_to(@intent, @subject, @override)} class={button_class(Map.get(@intent, :style), @override[:class])}>
          {@label}
        </a>
      <% :event -> %>
        <button
          type="button"
          phx-click={target_event(@intent, @override)}
          phx-value-id={@override[:id] || (@subject && @subject.id)}
          data-confirm={target_confirm(@intent, @override)}
          class={button_class(Map.get(@intent, :style), @override[:class])}
        >
          {@label}
        </button>
      <% :submit -> %>
        <button type="submit" class={button_class(Map.get(@intent, :style), @override[:class])}>
          {@label}
        </button>
      <% _ -> %>
    <% end %>
    """
  end

  defp target_to(intent, subject, override) do
    target = override[:target] || Map.get(intent, :target)

    case target do
      {:navigate, to} -> to
      {:patch, to} -> to
      _ -> nil
    end
    |> replace_subject_id(subject)
  end

  defp target_event(intent, override) do
    target = override[:target] || Map.get(intent, :target)

    case target do
      {:event, event} -> event
      _ -> to_string(intent.name)
    end
  end

  defp target_confirm(intent, override),
    do: Map.get(override, :confirm, Map.get(intent, :confirm))

  defp replace_subject_id(nil, _subject), do: nil
  defp replace_subject_id(to, nil), do: to
  defp replace_subject_id(to, subject), do: String.replace(to, ":id", to_string(subject.id))

  defp button_class(style, class) do
    [
      "btn btn-sm",
      case style do
        :primary -> "btn-primary"
        :secondary -> "btn-ghost"
        :destructive -> "btn-error btn-outline"
        :info -> "btn-info btn-outline"
        _ -> "btn-ghost"
      end,
      class
    ]
  end

  defp target_kind(intent, override) do
    case override[:target] || Map.get(intent, :target) do
      {:navigate, _} -> :link
      {:patch, _} -> :link
      {:event, _} -> :event
      {:ash_action, _} -> :submit
      _ -> nil
    end
  end

  defp visible?(intent, %{bindings: bindings}) do
    case Map.get(intent, :visible_when) do
      nil -> true
      binding when is_atom(binding) -> not is_nil(Map.get(bindings, binding))
      _ -> true
    end
  end
end
