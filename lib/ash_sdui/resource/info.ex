defmodule AshSDUI.Resource.Info do
  @moduledoc """
  Introspection API for `AshSDUI.Resource` DSL entities.
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

  @doc "Reads all `view` entities from the sdui block, or []."
  def views(resource) do
    (Spark.Dsl.Extension.get_entities(resource, [:sdui]) || [])
    |> Enum.filter(&is_struct(&1, AshSDUI.Resource.View))
  end

  @doc "Reads a named view entity from the sdui block."
  def view(resource, name) do
    resource
    |> views()
    |> Enum.find(&(&1.name == name))
  end

  @doc "Reads all `ui_intent` entities from the sdui block, or []."
  def ui_intents(resource) do
    (Spark.Dsl.Extension.get_entities(resource, [:sdui]) || [])
    |> Enum.filter(&is_struct(&1, AshSDUI.Resource.UiIntent))
  end

  @doc "Reads all `ui_field` entities from the sdui block, or []."
  def ui_fields(resource) do
    (Spark.Dsl.Extension.get_entities(resource, [:sdui]) || [])
    |> Enum.filter(&is_struct(&1, AshSDUI.Resource.UiField))
  end

  @doc "Reads all `ui_binding` entities from the sdui block, or []."
  def ui_bindings(resource) do
    (Spark.Dsl.Extension.get_entities(resource, [:sdui]) || [])
    |> Enum.filter(&is_struct(&1, AshSDUI.Resource.UiBinding))
  end

  @doc "Reads all `ui_query` entities from the sdui block, or []."
  def ui_queries(resource) do
    (Spark.Dsl.Extension.get_entities(resource, [:sdui]) || [])
    |> Enum.filter(&is_struct(&1, AshSDUI.Resource.UiQuery))
  end

  @doc """
  Resolves the display label for a DSL entity.

  Priority:
  1. `label`
  2. `label_key` via Gettext when a backend is configured
  3. titleized `name`
  """
  def resolve_label(entity, backend_or_module, domain \\ nil)

  def resolve_label(%{label: label}, _backend_or_module, _domain) when is_binary(label), do: label

  def resolve_label(%{label_key: key, name: name}, backend_or_module, domain)
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
    configured_backend =
      try do
        gettext_backend(backend_or_module)
      rescue
        _ -> nil
      end

    backend = configured_backend || backend_or_module

    domain =
      override_domain ||
        try do
          gettext_domain(backend_or_module)
        rescue
          _ -> "sdui"
        end

    {backend, domain}
  end
end
