defmodule AshSDUI.Intent do
  @moduledoc """
  Generic user intent model for views.

  Intents separate presentation metadata from execution targets so the same
  declarative definition can be rendered in different component systems.
  """

  alias AshSDUI.Context
  alias AshSDUI.Resource.Info

  defstruct [
    :name,
    :label,
    :style,
    :icon,
    :component_override,
    :target,
    :confirm,
    :placement,
    :requires_actor?,
    :visible_when,
    :source
  ]

  @type t :: %__MODULE__{
          name: atom,
          label: String.t(),
          style: atom | nil,
          icon: String.t() | nil,
          component_override: String.t() | nil,
          target: term,
          confirm: boolean | String.t() | nil,
          placement: atom | nil,
          requires_actor?: boolean,
          visible_when: atom | nil,
          source: term
        }

  @doc "Normalizes an intent declaration."
  @spec resolve(struct | map, module | Context.t() | map | keyword | nil) :: t
  def resolve(source, backend_or_context \\ nil)

  def resolve(%AshSDUI.Resource.UiIntent{} = source, backend_or_context) do
    backend = label_backend(source, backend_or_context)

    %__MODULE__{
      name: source.name,
      label: Info.resolve_label(source, backend),
      style: source.style,
      icon: source.icon,
      component_override: source.component_override,
      target: source.target || {:ash_action, source.name},
      confirm: source.confirm,
      placement: source.placement,
      requires_actor?: source.requires_actor?,
      visible_when: source.visible_when,
      source: source
    }
  end

  def resolve(source, _backend_or_context) when is_map(source) do
    struct(__MODULE__, source)
  end

  @doc """
  Executes an intent target when possible, otherwise returns a normalized runtime
  instruction tuple.
  """
  @spec execute(t | struct | map, map | keyword | nil, map | keyword | nil) ::
          {:ok, term} | {:error, term}
  def execute(intent, payload \\ %{}, runtime \\ %{})

  def execute(intent, payload, runtime) when not is_struct(intent, __MODULE__) do
    execute(resolve(intent), payload, runtime)
  end

  def execute(%__MODULE__{target: {:navigate, path}}, payload, _runtime),
    do: {:ok, {:navigate, interpolate(path, payload)}}

  def execute(%__MODULE__{target: {:patch, path}}, payload, _runtime),
    do: {:ok, {:patch, interpolate(path, payload)}}

  def execute(%__MODULE__{target: {:event, event}}, payload, _runtime),
    do: {:ok, {:event, event, normalize_payload(payload)}}

  def execute(%__MODULE__{target: {:refresh, binding}}, _payload, _runtime),
    do: {:ok, {:refresh, binding}}

  def execute(%__MODULE__{} = intent, payload, runtime)
      when is_tuple(intent.target) and elem(intent.target, 0) == :custom and
             tuple_size(intent.target) == 3 do
    {:custom, module, function} = intent.target

    if is_atom(module) and is_atom(function) do
      apply(module, function, [intent, normalize_payload(payload), normalize_runtime(runtime)])
    else
      {:error, {:invalid_custom_target, intent.target}}
    end
  end

  def execute(%__MODULE__{target: {:ash_action, action}} = intent, payload, runtime) do
    {:ok, {:ash_action, action, normalize_payload(payload), ash_runtime(intent, runtime)}}
  end

  def execute(%__MODULE__{target: target}, payload, runtime),
    do: {:ok, {:target, target, normalize_payload(payload), normalize_runtime(runtime)}}

  defp label_backend(_source, %Context{} = context), do: context.assigns[:ui]
  defp label_backend(_source, backend_or_module), do: backend_or_module

  defp ash_runtime(intent, runtime) do
    runtime = normalize_runtime(runtime)

    %{
      intent: intent.name,
      actor: runtime[:actor],
      tenant: runtime[:tenant],
      domain: runtime[:domain],
      resource: runtime[:resource],
      record: runtime[:record]
    }
  end

  defp interpolate(path, payload) when is_binary(path) do
    Enum.reduce(normalize_payload(payload), path, fn {key, value}, acc ->
      String.replace(acc, ":#{key}", to_string(value))
    end)
  end

  defp normalize_payload(nil), do: %{}
  defp normalize_payload(payload) when is_map(payload), do: payload
  defp normalize_payload(payload) when is_list(payload), do: Enum.into(payload, %{})
  defp normalize_payload(_payload), do: %{}

  defp normalize_runtime(nil), do: %{}
  defp normalize_runtime(runtime) when is_map(runtime), do: runtime
  defp normalize_runtime(runtime) when is_list(runtime), do: Enum.into(runtime, %{})
  defp normalize_runtime(_runtime), do: %{}
end
