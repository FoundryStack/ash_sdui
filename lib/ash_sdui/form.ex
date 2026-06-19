defmodule AshSDUI.Form do
  @moduledoc """
  Introspection helpers for building forms from SDUI metadata and Ash actions.
  """

  alias AshSDUI.Resource.Info

  @default_option_labels [:name, :title, :label, :username, :email]

  @doc """
  Returns ordered field metadata for an action using visible `ui_field`
  definitions that are accepted by that action.
  """
  def fields(resource_or_ui, action_name) do
    resource = Info.for_resource(resource_or_ui)
    action = Ash.Resource.Info.action(resource, action_name)

    accepted = accepted_fields(action)
    arguments = action_arguments(action)
    managed_relationships = managed_relationships(action)

    resource_or_ui
    |> Info.ui_fields()
    |> Enum.reject(& &1.hidden)
    |> Enum.reject(&(&1.form? == false))
    |> Enum.filter(&include_field?(&1, accepted, arguments, resource, managed_relationships))
    |> Enum.sort_by(& &1.order)
    |> Enum.map(
      &build_field(resource_or_ui, resource, action, &1, accepted, managed_relationships)
    )
  end

  def hydrate(resource_or_ui, action_name, fields, opts \\ []) do
    resource = Info.for_resource(resource_or_ui)
    action = Ash.Resource.Info.action(resource, action_name)
    accepted = accepted_fields(action)
    managed_relationships = managed_relationships(action)

    Enum.map(fields, fn field ->
      if relationship_selector?(field) do
        hydrated =
          Map.merge(
            field,
            resolve_relationship_metadata(
              resource_or_ui,
              resource,
              field,
              accepted,
              managed_relationships
            )
          )

        if hydrated.relationship do
          Map.put(hydrated, :options, load_relationship_options(resource, hydrated, opts))
        else
          raise ArgumentError,
                "generated select widget #{inspect(field.name)} must resolve to a relationship"
        end
      else
        field
      end
    end)
  end

  defp infer_widget(%{type: Ash.Type.Atom}), do: :text_input
  defp infer_widget(%{type: Ash.Type.String}), do: :text_input
  defp infer_widget(%{type: :string}), do: :text_input
  defp infer_widget(%{type: :utc_datetime}), do: :datetime
  defp infer_widget(_), do: :text_input

  defp build_field(resource_or_ui, resource, action, field, accepted, managed_relationships)
       when not is_nil(resource) do
    attribute = Ash.Resource.Info.attribute(resource, field.name)
    argument = action_argument(action, field.name)

    relationship =
      resolve_relationship_metadata(
        resource_or_ui,
        resource,
        field,
        accepted,
        managed_relationships
      )

    type = attribute_type(attribute, argument, relationship)
    required = required?(attribute, argument)

    %{
      name: field.name,
      label: Info.resolve_label(field, resource_or_ui),
      widget: relationship[:widget] || field.widget || infer_widget(attribute),
      field_component: field.field_component,
      type: type,
      required: required,
      input_source: input_source(field, accepted),
      relationship: relationship[:relationship],
      relationship_type: relationship[:relationship_type],
      option_label: relationship[:option_label],
      option_value: relationship[:option_value],
      prompt: relationship[:prompt],
      read_action: relationship[:read_action],
      options: [],
      multiple?: relationship[:multiple?] || false
    }
  end

  defp build_field(_resource_or_ui, _resource, _action, field, _accepted, _managed_relationships),
    do: field

  defp resolve_relationship_metadata(
         resource_or_ui,
         resource,
         field,
         _accepted,
         managed_relationships
       ) do
    case relationship_name(field, resource, managed_relationships) do
      nil ->
        %{
          relationship: nil,
          relationship_type: nil,
          option_label: nil,
          option_value: nil,
          prompt: nil,
          read_action: nil,
          multiple?: false,
          widget: field.widget
        }

      relationship_name ->
        relationship = relationship!(resource, relationship_name)
        value_field = relationship_value_field!(field, relationship)

        %{
          relationship: relationship_name,
          relationship_type: relationship.type,
          option_label: field.option_label || default_option_label(relationship.destination),
          option_value: value_field,
          prompt: field.prompt || default_prompt(field, resource_or_ui),
          read_action: field.read_action || default_read_action(relationship.destination),
          multiple?: multiple_relationship?(relationship),
          widget: field.widget || default_relationship_widget(relationship)
        }
    end
  end

  defp load_relationship_options(resource, field, opts) do
    relationship = relationship!(resource, field.relationship)
    destination = relationship.destination
    read_action = field.read_action || default_read_action(destination)
    label_field = field.option_label || default_option_label(destination)
    value_field = field.option_value || relationship_value_field!(field, relationship)

    destination
    |> Ash.read(
      action: read_action,
      actor: opts[:actor],
      tenant: opts[:tenant],
      domain: opts[:domain] || Ash.Resource.Info.domain(destination)
    )
    |> case do
      {:ok, records} ->
        Enum.map(records, fn record ->
          {option_label(record, label_field, destination), Map.get(record, value_field)}
        end)

      {:error, error} ->
        raise ArgumentError,
              "could not load relationship options for #{inspect(field.name)}: #{Exception.message(error)}"
    end
  end

  def initial_params(subject, fields) do
    fields
    |> Enum.filter(&(&1.input_source == :argument && relationship_selector?(&1)))
    |> Enum.reduce(%{}, fn field, params ->
      case field_value(subject, field) do
        nil -> params
        [] -> params
        value -> Map.put(params, Atom.to_string(field.name), value)
      end
    end)
  end

  def prepare_params(params, fields) do
    Enum.reduce(fields, params || %{}, fn field, acc ->
      if field.widget == :multiselect do
        Map.put_new(acc, Atom.to_string(field.name), [])
      else
        acc
      end
    end)
  end

  defp field_value(subject, %{relationship: nil, name: name}), do: Map.get(subject, name)

  defp field_value(subject, %{
         relationship: relationship_name,
         multiple?: false,
         option_value: option_value
       }) do
    case Map.get(subject, relationship_name) do
      nil -> nil
      record -> Map.get(record, option_value)
    end
  end

  defp field_value(subject, %{
         relationship: relationship_name,
         multiple?: true,
         option_value: option_value
       }) do
    subject
    |> Map.get(relationship_name, [])
    |> List.wrap()
    |> Enum.map(&Map.get(&1, option_value))
  end

  defp relationship_selector?(field) do
    Map.get(field, :relationship) || Map.get(field, :widget) in [:select, :multiselect]
  end

  defp include_field?(field, accepted, arguments, resource, managed_relationships) do
    MapSet.member?(accepted, field.name) ||
      MapSet.member?(arguments, field.name) ||
      not is_nil(field.relationship) ||
      not is_nil(infer_belongs_to_relationship(resource, field.name)) ||
      not is_nil(Map.get(managed_relationships, field.name))
  end

  defp accepted_fields(nil), do: MapSet.new()
  defp accepted_fields(%{accept: accept}), do: MapSet.new(accept || [])

  defp action_arguments(nil), do: MapSet.new()
  defp action_arguments(%{arguments: arguments}), do: MapSet.new(Enum.map(arguments, & &1.name))

  defp action_argument(nil, _name), do: nil

  defp action_argument(%{arguments: arguments}, name) do
    Enum.find(arguments || [], &(&1.name == name))
  end

  defp managed_relationships(nil), do: %{}

  defp managed_relationships(%{changes: changes}) do
    Enum.reduce(changes || [], %{}, fn
      %{change: {Ash.Resource.Change.ManageRelationship, opts}}, acc ->
        Map.put(acc, opts[:argument], opts[:relationship])

      _other, acc ->
        acc
    end)
  end

  defp input_source(field, accepted) do
    if MapSet.member?(accepted, field.name), do: :attribute, else: :argument
  end

  defp relationship_name(field, resource, managed_relationships) do
    field.relationship || infer_belongs_to_relationship(resource, field.name) ||
      Map.get(managed_relationships, field.name)
  end

  defp infer_belongs_to_relationship(resource, field_name) do
    resource
    |> Ash.Resource.Info.relationships()
    |> Enum.find(fn relationship ->
      relationship.type == :belongs_to && relationship.source_attribute == field_name
    end)
    |> case do
      nil -> nil
      relationship -> relationship.name
    end
  end

  defp relationship!(resource, relationship_name) do
    Enum.find(Ash.Resource.Info.relationships(resource), &(&1.name == relationship_name)) ||
      raise ArgumentError,
            "unknown relationship #{inspect(relationship_name)} for #{inspect(resource)}"
  end

  defp relationship_value_field!(field, relationship) do
    field.option_value ||
      case Ash.Resource.Info.primary_key(relationship.destination) do
        [primary_key] ->
          primary_key

        primary_key ->
          raise ArgumentError,
                "relationship selector #{inspect(field.name)} requires option_value for composite primary keys: #{inspect(primary_key)}"
      end
  end

  defp default_option_label(resource) do
    Enum.find(@default_option_labels, &Ash.Resource.Info.attribute(resource, &1)) ||
      List.first(Ash.Resource.Info.primary_key(resource)) ||
      raise ArgumentError, "could not infer option_label for #{inspect(resource)}"
  end

  defp default_read_action(resource) do
    resource
    |> Ash.Resource.Info.primary_action!(:read)
    |> Map.get(:name)
  end

  defp default_prompt(field, resource_or_ui) do
    "Choose #{String.downcase(Info.resolve_label(field, resource_or_ui))}"
  end

  defp default_relationship_widget(%{type: type}) when type in [:belongs_to, :has_one],
    do: :select

  defp default_relationship_widget(_relationship), do: :multiselect

  defp multiple_relationship?(%{type: type}) when type in [:has_many, :many_to_many], do: true
  defp multiple_relationship?(_relationship), do: false

  defp option_label(record, label_field, destination) do
    case Map.get(record, label_field) do
      nil ->
        destination
        |> Ash.Resource.Info.primary_key()
        |> Enum.map_join(" / ", &to_string(Map.get(record, &1)))

      value ->
        to_string(value)
    end
  end

  defp attribute_type(attribute, _argument, _relationship) when not is_nil(attribute),
    do: attribute.type

  defp attribute_type(_attribute, argument, _relationship) when not is_nil(argument),
    do: argument.type

  defp attribute_type(_attribute, _argument, _relationship), do: nil

  defp required?(attribute, _argument) when not is_nil(attribute),
    do: attribute.allow_nil? == false

  defp required?(_attribute, argument) when not is_nil(argument), do: argument.allow_nil? == false
  defp required?(_attribute, _argument), do: false
end
