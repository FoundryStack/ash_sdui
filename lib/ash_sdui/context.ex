defmodule AshSDUI.Context do
  @moduledoc """
  Runtime presentation context used while resolving SDUI views.

  The context is intentionally generic. Applications can pass actors, tenants,
  audiences, device hints, locale, or arbitrary assigns without AshSDUI baking in
  app-specific role or group concepts.
  """

  defstruct actor: nil,
            tenant: nil,
            locale: nil,
            audience: nil,
            device: nil,
            assigns: %{}

  @type t :: %__MODULE__{
          actor: term,
          tenant: term,
          locale: String.t() | nil,
          audience: atom | String.t() | nil,
          device: atom | String.t() | nil,
          assigns: map
        }

  @doc "Builds a context from a keyword list, map, or existing context."
  @spec new(keyword | map | t | nil) :: t
  def new(nil), do: %__MODULE__{}
  def new(%__MODULE__{} = context), do: context

  def new(opts) when is_list(opts) or is_map(opts) do
    opts = Enum.into(opts, %{})

    %__MODULE__{
      actor: Map.get(opts, :actor),
      tenant: Map.get(opts, :tenant),
      locale: Map.get(opts, :locale),
      audience: Map.get(opts, :audience),
      device: Map.get(opts, :device),
      assigns: Map.get(opts, :assigns, %{})
    }
  end

  @doc "Returns an assign from the context."
  @spec get_assign(t, atom | String.t(), term) :: term
  def get_assign(%__MODULE__{assigns: assigns}, key, default \\ nil) do
    Map.get(assigns, key, Map.get(assigns, to_string(key), default))
  end
end
