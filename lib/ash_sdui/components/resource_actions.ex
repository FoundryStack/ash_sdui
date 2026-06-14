defmodule AshSDUI.Components.ResourceActions do
  @moduledoc """
  DaisyUI-backed action renderer for `ui_action` metadata.
  """

  use Phoenix.Component

  alias AshSDUI.Resource.Info

  attr(:resource, :atom, required: true)
  attr(:subject, :any, default: nil)
  attr(:actions, :list, default: nil)
  attr(:overrides, :map, default: %{})
  attr(:placement, :atom, default: nil)
  attr(:class, :string, default: nil)

  def render(assigns) do
    actions =
      assigns.actions ||
        assigns.resource
        |> Info.ui_actions()
        |> Enum.map(fn action ->
          Map.put(action, :resolved_label, Info.resolve_label(action, assigns.resource))
        end)

    actions =
      if assigns.placement do
        Enum.filter(actions, &(&1.placement in [nil, assigns.placement]))
      else
        actions
      end

    assigns = assign(assigns, :actions, actions)

    ~H"""
    <div class={["flex flex-wrap justify-end gap-2", @class]} data-testid="resource-actions">
      <%= for action <- @actions do %>
        <.action action={action} subject={@subject} override={Map.get(@overrides, action.name, %{})} />
      <% end %>
    </div>
    """
  end

  attr(:action, :any, required: true)
  attr(:subject, :any, default: nil)
  attr(:override, :map, default: %{})

  def action(assigns) do
    kind = Map.get(assigns.override, :kind, Map.get(assigns.action, :kind))

    label =
      Map.get(assigns.action, :resolved_label) || Map.get(assigns.action, :label) ||
        to_string(assigns.action.name)

    assigns = assigns |> assign(:kind, kind) |> assign(:label, label)

    ~H"""
    <%= case @kind do %>
      <% :link -> %>
        <a href={target_to(@action, @subject, @override)} class={button_class(Map.get(@action, :intent), @override[:class])}>
          {@label}
        </a>
      <% :event -> %>
        <button
          type="button"
          phx-click={target_event(@action, @override)}
          phx-value-id={@override[:id] || (@subject && @subject.id)}
          data-confirm={target_confirm(@action, @override)}
          class={button_class(Map.get(@action, :intent), @override[:class])}
        >
          {@label}
        </button>
      <% :submit -> %>
        <button type="submit" class={button_class(Map.get(@action, :intent), @override[:class])}>
          {@label}
        </button>
      <% _ -> %>
    <% end %>
    """
  end

  defp target_to(action, subject, override) do
    override[:to]
    |> Kernel.||(Map.get(action, :to))
    |> replace_subject_id(subject)
  end

  defp target_event(action, override),
    do: override[:event] || Map.get(action, :event) || to_string(action.name)

  defp target_confirm(action, override),
    do: Map.get(override, :confirm, Map.get(action, :confirm))

  defp replace_subject_id(nil, _subject), do: nil
  defp replace_subject_id(to, nil), do: to
  defp replace_subject_id(to, subject), do: String.replace(to, ":id", to_string(subject.id))

  defp button_class(intent, class) do
    [
      "btn btn-sm",
      case intent do
        :primary -> "btn-primary"
        :secondary -> "btn-ghost"
        :destructive -> "btn-error btn-outline"
        :info -> "btn-info btn-outline"
        _ -> "btn-ghost"
      end,
      class
    ]
  end
end
