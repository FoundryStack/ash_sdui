defmodule AshSDUI.RuntimeTest do
  use ExUnit.Case, async: true

  alias AshSDUI.Binding
  alias AshSDUI.Layout.Node
  alias AshSDUI.Runtime.BindingSet
  alias AshSDUI.Runtime.Meta
  alias AshSDUI.Runtime.State
  alias AshSDUI.View

  test "meta embed and split roundtrip the runtime envelope" do
    node = %Node{
      component: "Example.Card@v1",
      binding: :feed,
      refresh: :subscription,
      variant: :warning,
      state_key: [:workflow, :state],
      static_props: %{"title" => "Feed"}
    }

    encoded = Meta.embed(node)
    assert encoded["title"] == "Feed"
    assert encoded["__ash_sdui__"][:binding] == :feed

    assert {%{"title" => "Feed"}, runtime_meta} = Meta.split(encoded)
    assert runtime_meta.binding == :feed
    assert runtime_meta.refresh == :subscription
    assert runtime_meta.variant == :warning
    assert runtime_meta.state_key == [:workflow, :state]
  end

  test "binding set resolves primary collection and record" do
    bindings = [
      Binding.resolve(%{name: :collection, many?: true, source: {:assign, :records}}),
      Binding.resolve(%{name: :record, many?: false, source: {:assign, :record}})
    ]

    values = %{collection: [%{id: "1"}], record: %{id: "2"}}

    assert BindingSet.primary_collection_name(bindings) == :collection
    assert BindingSet.primary_record_name(bindings) == :record
    assert BindingSet.primary_collection(bindings, values) == [%{id: "1"}]
    assert BindingSet.primary_record(bindings, values) == %{id: "2"}
  end

  test "state helpers update refresh selection workflow and slices" do
    state =
      %View.State{}
      |> State.apply_selection(%{"operation" => "add", "id" => "alpha"})
      |> State.apply_workflow(%{"event" => "review"})
      |> State.mark_binding_refreshed(:metrics)

    assert state.selected == ["alpha"]
    assert state.workflow.state == "review"
    assert state.refresh.metrics.status == :ready
    assert State.refresh_meta(state, :metrics).status == :ready
    assert State.state_slice(state, [:workflow, :state]) == "review"
    assert State.selected_records(state, [%{id: "alpha"}, %{id: "beta"}]) == [%{id: "alpha"}]
  end
end
