defmodule AshSDUI.FormTest do
  use ExUnit.Case, async: true

  alias AshSDUI.TestFixtures.ComponentFormResource
  alias AshSDUI.TestFixtures.FormResource

  test "fields/2 returns visible accepted attributes in order" do
    fields = AshSDUI.Form.fields(FormResource, :create)

    assert Enum.map(fields, & &1.name) == [:title, :body, :email]
    assert Enum.map(fields, & &1.label) == ["Title", "Body", "Email"]
  end

  test "fields/2 honors widget metadata" do
    fields = AshSDUI.Form.fields(FormResource, :create)

    assert Enum.find(fields, &(&1.name == :body)).widget == :textarea
    assert Enum.find(fields, &(&1.name == :email)).widget == :email
  end

  test "fields/2 includes custom field component metadata" do
    [field] = AshSDUI.Form.fields(ComponentFormResource, :create)
    assert field.field_component == ExampleFieldComponent
  end
end
