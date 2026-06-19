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

  test "merge_path preserves unrelated params and rewrites query params" do
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

    assert Query.merge_path("/posts", query, %{"tab" => "live", "offset" => "999"}) ==
             "/posts?limit=10&offset=20&search=launch&sort=-title&tab=live"
  end

  test "merge_path keeps plain path when query is nil" do
    assert Query.merge_path("/posts", nil, %{"tab" => "live"}) == "/posts"
  end

  test "to_params omits blank and default-shaped values" do
    query =
      Query.from_params(
        %{"search" => "   ", "filters" => %{"title" => ""}},
        %{
          name: :default,
          search: [:title],
          filters: [:title],
          sort: [:title],
          default_limit: 25
        }
      )

    assert Query.to_params(query) == %{"limit" => 25}
    assert Query.merge_path("/posts", query, %{"tab" => "live", "search" => "stale"}) ==
             "/posts?limit=25&tab=live"
  end

  test "query round-trips search filters and multi-sort cleanly" do
    query =
      Query.from_params(
        %{
          "search" => "launch",
          "sort" => "-title,+inserted_at",
          "filters" => %{"title" => "Guide"},
          "limit" => "10",
          "offset" => "20"
        },
        %{
          name: :default,
          search: [:title],
          sort: [:title, :inserted_at],
          filters: [:title],
          default_limit: 25
        }
      )

    assert Query.to_params(query) == %{
             "filters" => %{"title" => "Guide"},
             "limit" => 10,
             "offset" => 20,
             "search" => "launch",
             "sort" => "-title,inserted_at"
           }
  end

  test "update preserves unrelated current params while resetting offset on search-like events" do
    query =
      Query.from_params(
        %{"search" => "launch", "limit" => "10", "offset" => "20", "tab" => "live"},
        %{
          name: :default,
          search: [:title],
          sort: [:title],
          filters: [:title],
          default_limit: 25
        }
      )

    updated = Query.update(query, :search, %{"search" => "updated"})

    assert updated.search == "updated"
    assert updated.offset == nil
    assert updated.params["tab"] == "live"
    assert Query.merge_path("/posts", updated, updated.params) ==
             "/posts?limit=10&search=updated&tab=live"
  end
end
