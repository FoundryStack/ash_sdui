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
    :enabled_when,
    :loading_when,
    :refreshes,
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
          enabled_when: term,
          loading_when: term,
          refreshes: [atom] | nil,
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
      enabled_when: source.enabled_when,
      loading_when: source.loading_when,
      refreshes: source.refreshes || [],
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
  @spec command(t | struct | map, map | keyword | nil, map | keyword | nil) ::
          {:ok, map} | {:error, term}
  def command(intent, payload \\ %{}, runtime \\ %{})

  def command(intent, payload, runtime) when not is_struct(intent, __MODULE__) do
    command(resolve(intent), payload, runtime)
  end

  def command(%__MODULE__{target: {:navigate, path}} = intent, payload, runtime),
    do: ok_command(intent, :navigate, %{to: interpolate(path, payload)}, payload, runtime)

  def command(%__MODULE__{target: {:patch, path}} = intent, payload, runtime),
    do: ok_command(intent, :patch, %{to: interpolate(path, payload)}, payload, runtime)

  def command(%__MODULE__{target: {:event, event}} = intent, payload, runtime),
    do: ok_command(intent, :event, %{event: event}, payload, runtime)

  def command(%__MODULE__{target: {:refresh, binding}} = intent, payload, runtime),
    do: ok_command(intent, :refresh, %{binding: binding}, payload, runtime)

  def command(%__MODULE__{target: {:select, operation}} = intent, payload, runtime),
    do: ok_command(intent, :select, %{operation: operation}, payload, runtime)

  def command(%__MODULE__{target: {:workflow, event}} = intent, payload, runtime),
    do: ok_command(intent, :workflow, %{event: event}, payload, runtime)

  def command(%__MODULE__{} = intent, payload, runtime)
      when is_tuple(intent.target) and elem(intent.target, 0) == :custom and
             tuple_size(intent.target) == 3 do
    {:custom, module, function} = intent.target

    if is_atom(module) and is_atom(function) do
      apply(module, function, [intent, normalize_payload(payload), normalize_runtime(runtime)])
    else
      {:error, {:invalid_custom_target, intent.target}}
    end
  end

  def command(%__MODULE__{target: {:ash_action, action}} = intent, payload, runtime) do
    {:ok,
     %{
       type: :ash_action,
       intent: intent.name,
       payload: normalize_payload(payload),
       meta: %{action: action, runtime: ash_runtime(intent, runtime), refreshes: intent.refreshes}
     }}
  end

  def command(%__MODULE__{target: target} = intent, payload, runtime),
    do: ok_command(intent, :target, %{target: target}, payload, runtime)

  @spec execute(t | struct | map, map | keyword | nil, map | keyword | nil) ::
          {:ok, term} | {:error, term}
  def execute(intent, payload \\ %{}, runtime \\ %{})

  def execute(intent, payload, runtime) when not is_struct(intent, __MODULE__) do
    execute(resolve(intent), payload, runtime)
  end

  def execute(%__MODULE__{} = intent, payload, runtime) do
    case command(intent, payload, runtime) do
      {:ok, %{type: :navigate, meta: %{to: to}}} ->
        {:ok, {:navigate, to}}

      {:ok, %{type: :patch, meta: %{to: to}}} ->
        {:ok, {:patch, to}}

      {:ok, %{type: :event, meta: %{event: event}, payload: payload}} ->
        {:ok, {:event, event, payload}}

      {:ok, %{type: :refresh, meta: %{binding: binding}}} ->
        {:ok, {:refresh, binding}}

      {:ok, %{type: :ash_action, meta: %{action: action, runtime: runtime}, payload: payload}} ->
        {:ok, {:ash_action, action, payload, runtime}}

      {:ok, %{type: :target, meta: %{target: target}, payload: payload, runtime: runtime}} ->
        {:ok, {:target, target, payload, runtime}}

      other ->
        other
    end
  end

  defp label_backend(_source, %Context{} = context), do: context.assigns[:ui]
  defp label_backend(_source, backend_or_module), do: backend_or_module

  defp ok_command(intent, type, meta, payload, runtime) do
    {:ok,
     %{
       type: type,
       intent: intent.name,
       payload: normalize_payload(payload),
       runtime: normalize_runtime(runtime),
       meta: Map.merge(meta, %{refreshes: intent.refreshes || []})
     }}
  end

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
