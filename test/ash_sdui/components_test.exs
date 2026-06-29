defmodule AshSDUI.ComponentsTest do
  use ExUnit.Case, async: true

  defmodule Article do
    defstruct [:id, :title, :status]
  end

  defp html(rendered) do
    rendered
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  test "resource detail renders field labels and values" do
    rendered =
      AshSDUI.Components.RecordDetail.render(%{
        subject: %Article{id: "1", title: "Hello", status: "draft"},
        fields: [
          %{name: :title, label: "Title"},
          %{name: :status, label: "Status", badge?: true}
        ],
        __changed__: nil
      })

    output = html(rendered)

    assert output =~ "Title"
    assert output =~ "Hello"
    assert output =~ "badge"
  end

  test "record list renders rows and row intents" do
    intents = [
      %{
        name: :update,
        label: "Edit",
        style: :secondary,
        target: {:navigate, "/articles/:id/edit"},
        placement: :row
      }
    ]

    rendered =
      AshSDUI.Components.RecordList.render(%{
        records: [%Article{id: "1", title: "Hello"}],
        fields: [%{name: :title, label: "Title"}],
        intents: intents,
        ui: Article,
        __changed__: nil
      })

    output = html(rendered)

    assert output =~ "Hello"
    assert output =~ "/articles/1/edit"
  end

  test "empty collection renders empty state" do
    rendered =
      AshSDUI.Components.RecordList.render(%{
        records: [],
        fields: [%{name: :title, label: "Title"}],
        empty_title: "Nothing here",
        __changed__: nil
      })

    assert html(rendered) =~ "Nothing here"
  end

  test "field values can resolve from named bindings" do
    rendered =
      AshSDUI.Components.RecordDetail.render(%{
        subject: nil,
        bindings: %{profile: %Article{id: "1", title: "Hello"}},
        fields: [%{name: :title, label: "Title", binding: :profile}],
        __changed__: nil
      })

    assert html(rendered) =~ "Hello"
  end

  test "intent visibility can depend on a named binding" do
    rendered =
      AshSDUI.Components.IntentBar.render(%{
        ui: Article,
        bindings: %{selection: %Article{id: "1"}},
        intents: [
          %{
            name: :open,
            label: "Open",
            target: {:navigate, "/articles/1"},
            visible_when: :selection
          },
          %{
            name: :hidden,
            label: "Hidden",
            target: {:navigate, "/articles/2"},
            visible_when: :missing
          }
        ],
        __changed__: nil
      })

    output = html(rendered)

    assert output =~ "Open"
    refute output =~ "Hidden"
  end

  test "intent bar presentation centralizes enabled and loading state" do
    rendered =
      AshSDUI.Components.IntentBar.render(%{
        ui: Article,
        subject: %Article{id: "1", title: "Hello"},
        state: %AshSDUI.View.State{
          selected: ["1"],
          loading: %{approve: true},
          workflow: %{state: "review"}
        },
        intents: [
          %{
            name: :approve,
            label: "Approve",
            target: {:refresh, :view},
            enabled_when: {:selection, :any},
            loading_when: {:intent, :approve},
            confirm: "Approve this item?"
          }
        ],
        __changed__: nil
      })

    output = html(rendered)

    assert output =~ ~s(phx-click="intent")
    assert output =~ "Approve this item?"
    assert output =~ "loading"
  end

  test "intent buttons disable with a loading copy" do
    rendered =
      AshSDUI.Components.IntentBar.render(%{
        ui: Article,
        subject: %Article{id: "1", title: "Hello"},
        intents: [
          %{
            name: :approve,
            label: "Approve",
            target: {:refresh, :view},
            enabled_when: true
          }
        ],
        __changed__: nil
      })

    output = html(rendered)

    assert output =~ ~s(phx-disable-with="Refreshing...")
  end

  test "record list renders sync badges and skeleton rows while empty" do
    rendered =
      AshSDUI.Components.RecordList.render(%{
        records: [],
        fields: [%{name: :title, label: "Title"}],
        state: %AshSDUI.View.State{pending: %{refresh: %{status: :pending}}, offline: true},
        __changed__: nil
      })

    output = html(rendered)

    assert output =~ "Syncing"
    assert output =~ "Offline"
    assert output =~ "skeleton"
  end

  test "stream list renders sync badges and skeleton rows while empty" do
    rendered =
      AshSDUI.Components.StreamList.render(%{
        title: "Feed",
        binding_name: :collection,
        state: %AshSDUI.View.State{pending: %{refresh: %{status: :pending}}, offline: true},
        records: [],
        __changed__: nil
      })

    output = html(rendered)

    assert output =~ "Feed"
    assert output =~ "Syncing"
    assert output =~ "Offline"
    assert output =~ "skeleton"
  end

  test "stream list renders refresh metadata and empty state safely" do
    rendered =
      AshSDUI.Components.StreamList.render(%{
        title: "Feed",
        binding_name: :collection,
        state: %AshSDUI.View.State{
          refresh: %{collection: %{status: :loading, refreshed_at: ~U[2026-06-19 00:00:00Z]}}
        },
        records: [],
        __changed__: nil
      })

    output = html(rendered)

    assert output =~ "Feed"
    assert output =~ "Status: loading"
    assert output =~ "Updated 00:00:00"
    assert output =~ "No items"
  end

  test "selection bar hides for empty state and renders count for selected items" do
    hidden =
      AshSDUI.Components.SelectionBar.render(%{
        state: %AshSDUI.View.State{selected: []},
        __changed__: nil
      })

    refute html(hidden) =~ "selection-bar"

    visible =
      AshSDUI.Components.SelectionBar.render(%{
        state: %AshSDUI.View.State{selected: ["1", "2"]},
        label: "items selected",
        __changed__: nil
      })

    output = html(visible)

    assert output =~ "selection-bar"
    assert output =~ ~s(<span class="font-semibold">2</span> items selected)
  end
end
