defmodule SduiDemoWeb.Components.Layouts.PostShowActionBar do
  @moduledoc """
  Action bar for post show page — back button, edit, publish, and layout toggle tabs.

  Props:
    - post: nil (Post struct; determines whether publish button shows)
    - layout_mode: :standard (current layout mode for tab highlighting)
    - show_layout_toggle: true (boolean; whether to show layout toggle tabs)

  Events (sent to LiveView):
    - switch_layout — phx-value-mode="standard|blog|minimal"
    - publish — phx-click="publish"
  """

  use Phoenix.Component

  attr(:subject, :any, default: nil)
  attr(:props, :map, default: %{})
  attr(:children, :map, default: %{})
  attr(:region, :string, default: "default")

  # For direct component use (not via SDUI)
  attr(:post, :any, default: nil)
  attr(:layout_mode, :atom, default: :standard)
  attr(:show_layout_toggle, :boolean, default: true)

  def render(assigns) do
    # Support both SDUI props and direct attributes
    post = assigns.post || Map.get(assigns.props, "post", nil)
    layout_mode = assigns.layout_mode || Map.get(assigns.props, "layout_mode", :standard)

    show_layout_toggle =
      assigns.show_layout_toggle || Map.get(assigns.props, "show_layout_toggle", true)

    assigns =
      assigns
      |> assign(:post, post)
      |> assign(:layout_mode, layout_mode)
      |> assign(:show_layout_toggle, show_layout_toggle)

    ~H"""
    <div class="space-y-5">
      <div class="flex flex-wrap items-center gap-3">
        <a href="/posts" class="btn btn-ghost btn-sm">Back to journal</a>
        <div class="flex-1" />
        <.resource_actions
          resource={SduiDemo.UI.Resources.PostUI}
          subject={@post}
          overrides={
            %{
              update: %{kind: :link, to: "/posts/#{@post.id}/edit", class: "btn-outline"},
              publish:
                if(!@post.published_at,
                  do: %{kind: :event, event: "publish", class: "btn-success"},
                  else: nil
                )
            }
            |> Enum.reject(fn {_key, value} -> is_nil(value) end)
            |> Map.new()
          }
        />
      </div>

      <%= if @show_layout_toggle do %>
        <div class="tabs tabs-boxed border border-base-300 bg-base-100 p-1 shadow-sm">
          <button
            phx-click="switch_layout"
            phx-value-mode="standard"
            class={["tab", @layout_mode == :standard && "tab-active"]}
          >
            Standard
          </button>
          <button
            phx-click="switch_layout"
            phx-value-mode="blog"
            class={["tab", @layout_mode == :blog && "tab-active"]}
          >
            Blog
          </button>
          <button
            phx-click="switch_layout"
            phx-value-mode="minimal"
            class={["tab", @layout_mode == :minimal && "tab-active"]}
          >
            Minimal
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp resource_actions(assigns) do
    SduiDemoWeb.Components.ResourceActions.render(assigns)
  end
end
