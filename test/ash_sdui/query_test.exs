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

  test "date range filters convert into ash-friendly datetime bounds" do
    query =
      Query.from_params(
        %{
          "filters[published_at][from]" => "2024-01-01T08:00",
          "filters[published_at][to]" => "2024-01-31T17:30"
        },
        %{
          name: :default,
          filters: [:published_at]
        }
      )

    assert query.filters == %{
             published_at: %{"from" => "2024-01-01T08:00", "to" => "2024-01-31T17:30"}
           }

    assert Query.to_params(query) == %{
             "filters" => %{"published_at" => %{"from" => "2024-01-01T08:00", "to" => "2024-01-31T17:30"}}
           }

    assert Query.merge_path("/posts/generated", query) ==
             "/posts/generated?filters%5Bpublished_at%5D%5Bfrom%5D=2024-01-01T08%3A00&filters%5Bpublished_at%5D%5Bto%5D=2024-01-31T17%3A30"

    assert [filter: [published_at: range]] = Query.to_ash_opts(query)
    assert Keyword.get(range, :gte) == ~U[2024-01-01 08:00:00Z]
    assert Keyword.get(range, :lte) == ~U[2024-01-31 17:30:00Z]
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
