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
end
