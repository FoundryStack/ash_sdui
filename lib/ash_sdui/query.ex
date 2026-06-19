defmodule AshSDUI.Query do
  @moduledoc """
  Generic query-state model used by views and bindings.

  The struct captures the user-controlled parts of collection state in a runtime
  friendly way, while the query schema provides the allowed search, filter, and
  sort fields.
  """

  alias AshSDUI.Runtime.Normalize

  defstruct [
    :name,
    search_fields: [],
    filter_fields: [],
    sort_fields: [],
    default_sort: nil,
    default_limit: nil,
    params: %{},
    search: nil,
    filters: %{},
    sort: [],
    limit: nil,
    offset: nil,
    source: nil
  ]

  @type sort_direction :: :asc | :desc
  @type sort_entry :: atom | {atom, sort_direction}

  @type t :: %__MODULE__{
          name: atom | nil,
          search_fields: [atom],
          filter_fields: [atom],
          sort_fields: [atom],
          default_sort: sort_entry | [sort_entry] | nil,
          default_limit: pos_integer | nil,
          params: map,
          search: String.t() | nil,
          filters: map,
          sort: [sort_entry],
          limit: pos_integer | nil,
          offset: non_neg_integer | nil,
          source: term
        }

  @doc "Builds a runtime query from params and a declared schema."
  @spec from_params(map | keyword | nil, struct | map | nil) :: t | nil
  def from_params(_params, nil), do: nil

  def from_params(params, schema) do
    params = Normalize.mapify(params)

    %__MODULE__{
      name: Map.get(schema, :name),
      search_fields: normalize_atom_list(Map.get(schema, :search, [])),
      filter_fields: normalize_atom_list(Map.get(schema, :filters, [])),
      sort_fields: normalize_atom_list(Map.get(schema, :sort, [])),
      default_sort: Map.get(schema, :default_sort),
      default_limit: Map.get(schema, :default_limit),
      params: params,
      search: normalize_search(Map.get(params, "search") || Map.get(params, :search)),
      filters: normalize_filters(params, schema),
      sort:
        params
        |> Map.get("sort", Map.get(params, :sort))
        |> normalize_sort(Map.get(schema, :sort, []), Map.get(schema, :default_sort)),
      limit:
        normalize_integer(
          Map.get(params, "limit") || Map.get(params, :limit),
          Map.get(schema, :default_limit)
        ),
      offset: normalize_integer(Map.get(params, "offset") || Map.get(params, :offset), nil),
      source: schema
    }
  end

  @doc "Updates a query from a named event and params."
  @spec update(t | nil, atom, map | keyword | nil) :: t | nil
  def update(nil, _event, _params), do: nil

  def update(%__MODULE__{} = query, :reset, _params) do
    from_params(%{}, query_schema(query))
  end

  def update(%__MODULE__{} = query, event, params)
      when event in [:params, :search, :filter, :sort, :paginate] do
    merged =
      query.params
      |> Map.merge(Normalize.mapify(params))
      |> maybe_reset_offset(event)

    from_params(merged, query_schema(query))
  end

  @doc "Converts query state into Ash read options."
  @spec to_ash_opts(t | nil, keyword) :: keyword
  def to_ash_opts(query, opts \\ [])
  def to_ash_opts(nil, opts), do: opts

  def to_ash_opts(%__MODULE__{} = query, opts) do
    opts
    |> Normalize.maybe_put_keyword(:filter, ash_filter(query))
    |> Normalize.maybe_put_keyword(:sort, ash_sort(query))
    |> Normalize.maybe_put_keyword(:page, ash_page(query))
  end

  @doc "Serializes a runtime query back into URL params."
  @spec to_params(t | nil) :: map
  def to_params(nil), do: %{}

  def to_params(%__MODULE__{} = query) do
    %{}
    |> Normalize.maybe_put_map("search", query.search)
    |> Normalize.maybe_put_map("limit", query.limit)
    |> Normalize.maybe_put_map("offset", query.offset)
    |> Normalize.maybe_put_map("sort", sort_query_param(query.sort))
    |> Normalize.maybe_put_map("filters", stringify_keys(query.filters))
  end

  @doc "Merges query params into a path while preserving unrelated params."
  @spec merge_path(String.t(), t | nil, map | nil) :: String.t()
  def merge_path(path, query, current_params \\ %{})

  def merge_path(path, nil, _current_params), do: path

  def merge_path(path, %__MODULE__{} = query, current_params) do
    params =
      current_params
      |> normalize_params()
      |> Map.merge(to_params(query))
      |> Enum.reject(fn {_key, value} -> blank_query_value?(value) end)
      |> Enum.into(%{})

    case URI.encode_query(params) do
      "" -> path
      encoded -> path <> "?" <> encoded
    end
  end

  defp query_schema(query) do
    %{
      name: query.name,
      search: query.search_fields,
      filters: query.filter_fields,
      sort: query.sort_fields,
      default_sort: query.default_sort,
      default_limit: query.default_limit
    }
  end

  defp ash_filter(%__MODULE__{search: nil, filters: filters}) when map_size(filters) == 0, do: nil

  defp ash_filter(%__MODULE__{} = query) do
    []
    |> maybe_add_search(query.search, query.search_fields)
    |> Enum.concat(Enum.map(query.filters, fn {field, value} -> {field, value} end))
    |> case do
      [] -> nil
      filters -> filters
    end
  end

  defp maybe_add_search(filters, nil, _fields), do: filters
  defp maybe_add_search(filters, "", _fields), do: filters
  defp maybe_add_search(filters, _search, []), do: filters

  defp maybe_add_search(filters, search, fields) do
    keyword_filters =
      Enum.map(fields, fn field ->
        {field, [contains: search]}
      end)

    [[or: keyword_filters] | filters]
  end

  defp ash_sort(%__MODULE__{sort: []}), do: nil
  defp ash_sort(%__MODULE__{sort: sort}), do: sort

  defp ash_page(%__MODULE__{limit: nil, offset: nil}), do: nil

  defp ash_page(%__MODULE__{} = query) do
    []
    |> Normalize.maybe_put_keyword(:limit, query.limit)
    |> Normalize.maybe_put_keyword(:offset, query.offset)
  end

  defp normalize_filters(params, schema) do
    declared = normalize_atom_list(Map.get(schema, :filters, []))
    raw = Map.get(params, "filters") || Map.get(params, :filters) || %{}
    raw = Normalize.mapify(raw)

    declared
    |> Enum.reduce(%{}, fn field, acc ->
      string_key = Atom.to_string(field)
      value = Map.get(raw, string_key) || Map.get(raw, field)

      if blank?(value) do
        acc
      else
        Map.put(acc, field, value)
      end
    end)
  end

  defp normalize_sort(nil, _allowed, default_sort), do: List.wrap(default_sort)
  defp normalize_sort("", _allowed, default_sort), do: List.wrap(default_sort)

  defp normalize_sort(sort, allowed, _default_sort) do
    allowed =
      allowed
      |> normalize_atom_list()
      |> Enum.map(&{Atom.to_string(&1), &1})
      |> Map.new()

    sort
    |> List.wrap()
    |> Enum.flat_map(&split_sort_input/1)
    |> Enum.map(&parse_sort_entry(&1, allowed))
    |> Enum.filter(fn
      {field, _dir} -> Map.has_key?(allowed, Atom.to_string(field))
      field when is_atom(field) -> Map.has_key?(allowed, Atom.to_string(field))
      _ -> false
    end)
  end

  defp split_sort_input(sort) when is_binary(sort), do: String.split(sort, ",", trim: true)
  defp split_sort_input(sort), do: [sort]

  defp parse_sort_entry("-" <> field, allowed), do: {Map.get(allowed, field), :desc}

  defp parse_sort_entry("+" <> field, allowed), do: {Map.get(allowed, field), :asc}

  defp parse_sort_entry(field, allowed) when is_binary(field), do: Map.get(allowed, field)
  defp parse_sort_entry({field, dir}, _allowed) when dir in [:asc, :desc], do: {field, dir}
  defp parse_sort_entry(field, _allowed) when is_atom(field), do: field
  defp parse_sort_entry(other, _allowed), do: other

  defp normalize_search(search) when is_binary(search) do
    search = String.trim(search)
    if search == "", do: nil, else: search
  end

  defp normalize_search(_search), do: nil

  defp normalize_integer(nil, default), do: default
  defp normalize_integer("", default), do: default

  defp normalize_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} when int >= 0 -> int
      _ -> default
    end
  end

  defp normalize_integer(value, _default) when is_integer(value) and value >= 0, do: value
  defp normalize_integer(_value, default), do: default

  defp normalize_atom_list(list) do
    list
    |> List.wrap()
    |> Enum.filter(&is_atom/1)
  end

  defp maybe_reset_offset(params, event) when event in [:search, :filter, :sort] do
    Map.delete(params, "offset")
    |> Map.delete(:offset)
  end

  defp maybe_reset_offset(params, _event), do: params

  defp normalize_params(params) when is_map(params) do
    params
    |> Map.drop([
      "search",
      "sort",
      "limit",
      "offset",
      "filters",
      :search,
      :sort,
      :limit,
      :offset,
      :filters
    ])
    |> stringify_keys()
  end

  defp normalize_params(_params), do: %{}

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {
        if(is_atom(key), do: Atom.to_string(key), else: key),
        if(is_map(value), do: stringify_keys(value), else: value)
      }
    end)
  end

  defp stringify_keys(value), do: value

  defp sort_query_param([]), do: nil

  defp sort_query_param(sort) do
    Enum.map_join(sort, ",", fn
      {field, :desc} -> "-" <> Atom.to_string(field)
      {field, :asc} -> Atom.to_string(field)
      field when is_atom(field) -> Atom.to_string(field)
    end)
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_), do: false

  defp blank_query_value?(nil), do: true
  defp blank_query_value?(""), do: true
  defp blank_query_value?(%{}), do: true

  defp blank_query_value?(value) when is_map(value),
    do: Enum.all?(value, fn {_k, v} -> blank_query_value?(v) end)

  defp blank_query_value?(_value), do: false
end
