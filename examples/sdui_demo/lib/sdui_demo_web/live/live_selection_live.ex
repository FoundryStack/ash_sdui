defmodule SduiDemoWeb.Live.LiveSelectionLive do
  use SduiDemoWeb, :live_view

  alias AshSDUI.View

  @items [
    %{id: "sel-1", title: "Operator dashboard", detail: "Selection-aware list row"},
    %{
      id: "sel-2",
      title: "Fraud queue",
      detail: "Intent availability depends on selection state"
    },
    %{id: "sel-3", title: "VIP profile", detail: "Bulk actions stay generic"}
  ]

  @intents [
    %{
      name: :clear_selection,
      label: "Clear",
      style: :secondary,
      target: {:select, :clear},
      enabled_when: {:selection, :any}
    },
    %{
      name: :pin_selection,
      label: "Pin Selection",
      style: :primary,
      target: {:event, "pin_selection"},
      enabled_when: {:selection, :any}
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Selection State",
       items: @items,
       pinned: [],
       bindings: %{},
       intents: @intents,
       state: %View.State{selected: []}
     )}
  end

  @impl true
  def handle_event("select", %{"id" => id}, socket) do
    selected =
      if id in socket.assigns.state.selected do
        Enum.reject(socket.assigns.state.selected, &(&1 == id))
      else
        socket.assigns.state.selected ++ [id]
      end

    {:noreply, assign(socket, :state, %{socket.assigns.state | selected: selected})}
  end

  def handle_event("intent", %{"intent" => "clear_selection"}, socket) do
    {:noreply, assign(socket, :state, %{socket.assigns.state | selected: []})}
  end

  def handle_event("pin_selection", _params, socket) do
    pinned =
      socket.assigns.items
      |> Enum.filter(&(&1.id in socket.assigns.state.selected))

    {:noreply, assign(socket, :pinned, pinned)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto flex w-full max-w-5xl flex-col gap-6 px-4 py-10">
      <header class="space-y-3">
        <p class="text-sm uppercase tracking-[0.2em] text-base-content/60">Selection Runtime</p>
        <h1 class="text-4xl font-semibold">Selection-aware intents</h1>
        <p class="max-w-3xl text-base-content/75">
          Selection is modeled as runtime state rather than a one-off table hack, so generic components can light up intent availability and summary UI consistently.
        </p>
      </header>

      <AshSDUI.Components.SelectionBar.render count={length(@state.selected)} label="items selected">
        <AshSDUI.Components.IntentBar.render
          ui={SduiDemo.UI.Resources.PostUI}
          intents={@intents}
          bindings={@bindings}
          state={@state}
        />
      </AshSDUI.Components.SelectionBar.render>

      <section class="rounded-box border border-base-300 bg-base-100">
        <article
          :for={item <- @items}
          class="flex items-start gap-4 border-b border-base-200 px-4 py-4 last:border-b-0"
        >
          <input
            type="checkbox"
            class="checkbox checkbox-sm mt-1"
            checked={item.id in @state.selected}
            phx-click="select"
            phx-value-id={item.id}
          />
          <div class="space-y-1">
            <h2 class="font-medium">{item.title}</h2>
            <p class="text-sm text-base-content/70">{item.detail}</p>
          </div>
        </article>
      </section>

      <AshSDUI.Components.ActivityFeed.render
        items={Enum.map(@pinned, &%{title: &1.title, meta: "Pinned", body: &1.detail})}
        empty_title="Select and pin a few rows to see selection-aware actions in motion"
      />
    </main>
    """
  end
end
