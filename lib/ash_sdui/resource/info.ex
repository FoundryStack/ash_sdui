defmodule AshSDUI.Resource.Info do
  @moduledoc """
  Introspection API for AshSDUI.Resource DSL extensions.

  Works with both inline Ash extensions and standalone UI modules.

  ## Label resolution

  Labels can be either hardcoded strings (`label: "Username"`) or gettext keys
  (`label_key: "user.username"`). Use `resolve_label/2` to get the final string:

      AshSDUI.Resource.Info.resolve_label(attr, MyApp.Gettext)
      # => calls Gettext.dgettext(MyApp.Gettext, "sdui", "user.username")

  Configure a default backend on the UI module:

      sdui do
        gettext_backend MyApp.Gettext
        ui_attribute :username, label_key: "user.username"
      end

  Then resolve without passing the backend explicitly:

      AshSDUI.Resource.Info.resolve_label(attr, MyUIModule)
  """

  require Spark.Dsl.Extension

  @doc "Reads the `:default_component` option from the sdui block, or nil."
  def default_component(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:sdui], :default_component, nil)
  end

  @doc """
  Returns the Ash resource this module annotates.

  For inline Ash extensions, returns the module itself.
  For standalone UI modules (`use AshSDUI.Resource.Standalone`), returns the `for_resource`.
  """
  def for_resource(module) do
    Spark.Dsl.Extension.get_opt(module, [:sdui], :for_resource, module)
  end

  @doc "Returns the configured gettext backend module, or nil."
  def gettext_backend(module) do
    Spark.Dsl.Extension.get_opt(module, [:sdui], :gettext_backend, nil)
  end

  @doc "Returns the configured gettext domain (default: \"sdui\")."
  def gettext_domain(module) do
    Spark.Dsl.Extension.get_opt(module, [:sdui], :gettext_domain, "sdui")
  end

  @doc "Reads all `ui_action` entities from the sdui block, or []."
  def ui_actions(resource) do
    (Spark.Dsl.Extension.get_entities(resource, [:sdui]) || [])
    |> Enum.filter(&is_struct(&1, AshSDUI.Resource.UiAction))
  end

  @doc "Reads all `ui_attribute` entities from the sdui block, or []."
  def ui_attributes(resource) do
    (Spark.Dsl.Extension.get_entities(resource, [:sdui]) || [])
    |> Enum.filter(&is_struct(&1, AshSDUI.Resource.UiAttribute))
  end

  @doc """
  Resolves the display label for a `UiAction` or `UiAttribute`.

  Priority:
  1. `label` field (hardcoded string) — returned as-is
  2. `label_key` field — looked up via `Gettext.dgettext/3` using the provided backend
  3. Falls back to the atom name stringified (e.g. `:username` → `"username"`)

  The `backend_or_module` can be either:
  - A Gettext backend module directly (e.g. `MyApp.Gettext`)
  - A UI annotation module whose `gettext_backend` option will be read

  Pass `domain` to override the gettext domain (default reads from the module or "sdui").
  """
  def resolve_label(entity, backend_or_module, domain \\ nil)

  def resolve_label(%{label: label}, _backend_or_module, _domain) when is_binary(label) do
    label
  end

  def resolve_label(%{label_key: key, name: name} = _entity, backend_or_module, domain)
      when is_binary(key) do
    {backend, resolved_domain} = resolve_gettext_config(backend_or_module, domain)

    gettext_mod = Module.concat(["Gettext"])

    if backend && Code.ensure_loaded?(backend) && function_exported?(backend, :lgettext, 4) &&
         Code.ensure_loaded?(gettext_mod) do
      apply(gettext_mod, :dgettext, [backend, resolved_domain, key])
    else
      to_string(name)
    end
  end

  def resolve_label(%{name: name}, _backend_or_module, _domain) do
    name |> to_string() |> String.replace("_", " ") |> :string.titlecase() |> to_string()
  end

  defp resolve_gettext_config(backend_or_module, override_domain) do
    # Check if it's a UI annotation module with gettext_backend configured
    configured_backend =
      try do
        gettext_backend(backend_or_module)
      rescue
        _ -> nil
      end

    backend = configured_backend || backend_or_module

    domain =
      override_domain ||
        (try do
           gettext_domain(backend_or_module)
         rescue
           _ -> "sdui"
         end)

    {backend, domain}
  end
end
