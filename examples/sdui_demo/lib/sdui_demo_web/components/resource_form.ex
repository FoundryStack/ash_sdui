defmodule SduiDemoWeb.Components.ResourceForm do
  @moduledoc false

  use Phoenix.Component

  attr(:form, :any, required: true)
  attr(:resource, :atom, required: true)
  attr(:action, :atom, required: true)
  attr(:change_event, :string, default: "validate")
  attr(:submit_event, :string, default: "save")
  attr(:field_overrides, :map, default: %{})
  attr(:class, :string, default: nil)
  slot(:extra_fields)
  slot(:footer)

  def render(assigns) do
    assigns =
      assigns
      |> assign(:ui, assigns.resource)
      |> assign_new(:fields, fn -> AshSDUI.Form.fields(assigns.resource, assigns.action) end)

    AshSDUI.Components.RecordForm.render(assigns)
  end
end
