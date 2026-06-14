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
      AshSDUI.Components.ResourceDetail.render(%{
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

  test "resource collection renders rows and row actions" do
    actions = [
      %{
        name: :update,
        label: "Edit",
        intent: :secondary,
        kind: :link,
        to: "/articles/:id/edit",
        placement: :row
      }
    ]

    rendered =
      AshSDUI.Components.ResourceCollection.render(%{
        records: [%Article{id: "1", title: "Hello"}],
        fields: [%{name: :title, label: "Title"}],
        actions: actions,
        resource: Article,
        __changed__: nil
      })

    output = html(rendered)

    assert output =~ "Hello"
    assert output =~ "/articles/1/edit"
  end

  test "empty collection renders empty state" do
    rendered =
      AshSDUI.Components.ResourceCollection.render(%{
        records: [],
        fields: [%{name: :title, label: "Title"}],
        empty_title: "Nothing here",
        __changed__: nil
      })

    assert html(rendered) =~ "Nothing here"
  end
end
