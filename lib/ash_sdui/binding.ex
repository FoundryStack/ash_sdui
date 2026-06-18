defmodule AshSDUI.Binding do
  @moduledoc """
  Generic data binding model for views.

  Bindings describe where data comes from. The current implementation supports
  planning and basic runtime loading for Ash resources, relationships, and
  assigns, while staying small enough to compose declaratively in the SDUI DSL.
  """

  alias AshSDUI.Binding.Loader
  alias AshSDUI.Binding.Source
  alias AshSDUI.Binding.Subscription
  alias AshSDUI.Binding.Update
  alias AshSDUI.Context
  alias AshSDUI.Query

  defstruct [
    :name,
    :source,
    :many?,
    :query,
    :default,
    :value,
    :source_meta,
    refresh: :manual,
    update: :replace,
    update_strategy: :replace,
    source_kind: :static,
    status: :ready,
    subscription: nil
  ]

  @type t :: %__MODULE__{
          name: atom,
          source: term,
          many?: boolean,
          query: Query.t() | atom | nil,
          default: term,
          value: term,
          source_meta: term,
          refresh: term,
          update: term,
          update_strategy: atom | term,
          source_kind: atom,
          status: atom,
          subscription: map | nil
        }

  @doc "Normalizes a binding source into a concrete runtime binding."
  @spec resolve(struct | map, Context.t() | map | keyword | nil) :: t
  def resolve(binding, context \\ nil), do: Source.resolve(binding, context)

  @doc "Builds a loading plan for a list of bindings."
  @spec plan([struct | map], Context.t() | map | keyword | nil) :: [t]
  def plan(bindings, context \\ nil) do
    Enum.map(List.wrap(bindings), &resolve(&1, context))
  end

  @doc "Loads binding values that require an Ash read."
  @spec load([t], keyword) :: {:ok, map} | {:error, term}
  def load(bindings, opts \\ []), do: Loader.load(bindings, opts)

  @doc "Returns normalized subscription specs for bindings that can update live."
  @spec subscription_specs([t], keyword) :: [map]
  def subscription_specs(bindings, opts \\ []), do: Subscription.subscription_specs(bindings, opts)

  @doc "Normalizes an incoming live update and applies it to the current binding value."
  @spec apply_update(t, term, term) :: {:ok, term, map} | {:error, term}
  def apply_update(%__MODULE__{} = binding, current, message),
    do: Update.apply_update(binding, current, message)

  @doc "Returns true when a message matches a binding subscription spec."
  @spec subscription_match?(t, term) :: boolean
  def subscription_match?(binding, message), do: Subscription.subscription_match?(binding, message)

  def normalize_update_strategy(strategy)
       when strategy in [:replace, :append, :prepend, :merge, :remove],
       do: strategy

  def normalize_update_strategy(other), do: other
end
