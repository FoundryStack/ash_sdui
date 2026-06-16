defmodule AshSDUI.QueryTest do
  use ExUnit.Case, async: true

  alias AshSDUI.Query

  test "to_ash_opts encodes pagination in the page option" do
    query =
      Query.from_params(
        %{"search" => "launch", "sort" => "-title", "limit" => "10", "offset" => "20"},
        %{
          name: :default,
          search: [:title],
          sort: [:title],
          filters: [:title],
          default_limit: 25
        }
      )

    opts = Query.to_ash_opts(query)

    assert Keyword.get(opts, :filter) == [[or: [title: [contains: "launch"]]]]
    assert Keyword.get(opts, :sort) == [{:title, :desc}]
    assert Keyword.get(opts, :page) == [offset: 20, limit: 10]
  end
end
