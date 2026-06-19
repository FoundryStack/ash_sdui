defmodule AshSDUI.Binding.Source do
  @moduledoc false

  alias AshSDUI.Binding
  alias AshSDUI.Context

  @spec resolve(struct | map, Context.t() | map | keyword | nil) :: Binding.t()
  def resolve(binding, context \\ nil) do
    context = Context.new(context)
    source = Map.get(binding, :source)
    many? = infer_many?(binding, source)

    %Binding{
      name: Map.get(binding, :name),
      source: source,
      many?: many?,
      query: Map.get(binding, :query),
      default: Map.get(binding, :default),
      value: resolve_value(source, context, Map.get(binding, :default)),
      source_meta: binding,
      refresh: normalize_refresh(Map.get(binding, :refresh, infer_refresh(source))),
      update: Binding.normalize_update_strategy(Map.get(binding, :update, :replace)),
      update_strategy: Binding.normalize_update_strategy(Map.get(binding, :update, :replace)),
      source_kind: infer_source_kind(source),
      status: infer_status(source),
      subscription: build_subscription(source)
    }
  end

  @spec resolve_value(term, Context.t(), term) :: term
  def resolve_value({:assign, key}, %Context{assigns: assigns}, default) do
    Map.get(assigns, key, default)
  end

  def resolve_value({:context, key}, %Context{} = context, default) do
    Map.get(Map.from_struct(context), key, default)
  end

  def resolve_value({:runtime, key}, %Context{assigns: assigns}, default) do
    Map.get(assigns[:runtime] || %{}, key, default)
  end

  def resolve_value(source, context, default) do
    canonical = canonical_source(source)

    if canonical == source do
      do_resolve_value(source, context, default)
    else
      resolve_value(canonical, context, default)
    end
  end

  @spec infer_source_kind(term) :: atom
  def infer_source_kind({:resource, _}), do: :resource
  def infer_source_kind({:relationship, _}), do: :relationship
  def infer_source_kind({:assign, _}), do: :assign
  def infer_source_kind({:context, _}), do: :context
  def infer_source_kind({:runtime, _}), do: :runtime
  def infer_source_kind({:event, _}), do: :event
  def infer_source_kind({:selection}), do: :selection
  def infer_source_kind({:subject}), do: :subject
  def infer_source_kind({:actor}), do: :context
  def infer_source_kind({:tenant}), do: :context
  def infer_source_kind({:poll, _, _}), do: :poll
  def infer_source_kind({:pubsub, _, _}), do: :pubsub
  def infer_source_kind({:stream, _, _}), do: :stream
  def infer_source_kind(_), do: :static

  @spec canonical_source(term) :: term
  def canonical_source({:poll, source, _opts}), do: canonical_source(source)
  def canonical_source({:stream, source, _opts}), do: canonical_source(source)

  def canonical_source({:pubsub, _topic, opts}) do
    opts
    |> Keyword.get(:source)
    |> canonical_source()
  end

  def canonical_source(source), do: source

  defp infer_many?(binding, source) do
    case Map.get(binding, :many?) do
      value when is_boolean(value) -> value
      nil -> infer_many_from_source(source)
    end
  end

  defp infer_many_from_source(source) do
    case canonical_source(source) do
      {:resource, _} -> true
      {:relationship, _} -> true
      _ -> false
    end
  end

  defp infer_refresh({:poll, _source, opts}), do: Keyword.get(opts, :interval, :interval)
  defp infer_refresh({:pubsub, _topic, _opts}), do: :subscription
  defp infer_refresh({:stream, _source, _opts}), do: :subscription
  defp infer_refresh(_source), do: :manual

  defp infer_status({:poll, _, _}), do: :scheduled
  defp infer_status({:pubsub, _, _}), do: :subscribed
  defp infer_status({:stream, _, _}), do: :streaming
  defp infer_status(_source), do: :ready

  defp build_subscription({:poll, _source, opts}) do
    %{kind: :poll, interval: Keyword.fetch!(opts, :interval)}
  end

  defp build_subscription({:pubsub, topic, opts}) do
    %{
      kind: :pubsub,
      topic: topic,
      event: Keyword.get(opts, :event),
      reducer: Keyword.get(opts, :reducer),
      key: Keyword.get(opts, :key, :id)
    }
  end

  defp build_subscription({:stream, _source, opts}) do
    %{
      kind: :stream,
      event: Keyword.get(opts, :event),
      reducer: Keyword.get(opts, :reducer),
      key: Keyword.get(opts, :key, :id)
    }
  end

  defp build_subscription(_source), do: nil

  defp normalize_refresh({:interval, ms}) when is_integer(ms) and ms > 0, do: {:interval, ms}
  defp normalize_refresh(ms) when is_integer(ms) and ms > 0, do: {:interval, ms}
  defp normalize_refresh(other), do: other

  defp do_resolve_value({:selection}, %Context{assigns: assigns}, default) do
    Map.get(assigns, :selection, default)
  end

  defp do_resolve_value({:subject}, %Context{assigns: assigns}, default) do
    Map.get(assigns, :subject, default)
  end

  defp do_resolve_value({:actor}, %Context{actor: actor}, default), do: actor || default
  defp do_resolve_value({:tenant}, %Context{tenant: tenant}, default), do: tenant || default
  defp do_resolve_value(_source, _context, default), do: default
end
