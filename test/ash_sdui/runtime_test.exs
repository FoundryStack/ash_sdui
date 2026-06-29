defmodule AshSDUI.RuntimeTest do
  use ExUnit.Case, async: true

  alias AshSDUI.Binding
  alias AshSDUI.Binding.Source
  alias AshSDUI.Layout.Node
  alias AshSDUI.Runtime.BindingSet
  alias AshSDUI.Runtime.Meta
  alias AshSDUI.Runtime.State
  alias AshSDUI.View

  defp feed_binding(attrs) do
    defaults = %{
      name: :feed,
      source: {:stream, {:assign, :seed_feed}, [event: :feed_update, reducer: :stream_event]},
      many?: true
    }

    Binding.resolve(Map.merge(defaults, attrs))
  end

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

  test "state helpers track pending offline and error metadata" do
    state =
      %View.State{}
      |> State.begin_operation(:save, %{kind: :form, optimistic: %{title: "Draft"}})
      |> State.record_error(:save, :validation_error)
      |> State.mark_offline(:disconnected)

    assert State.pending_operation?(state, :save)
    assert State.pending_count(state) == 1
    assert State.optimistic_operations(state).save == %{title: "Draft"}
    assert State.offline?(state)
    assert State.last_error(state).reason == :validation_error

    cleared =
      state
      |> State.complete_operation(:save)
      |> State.clear_errors()
      |> State.mark_online()

    refute State.pending_operation?(cleared, :save)
    refute State.offline?(cleared)
    assert State.errors(cleared) == %{}
  end

  test "binding canonical source unwraps live wrappers consistently" do
    assert Source.canonical_source({:poll, {:resource, Article}, interval: 5_000}) ==
             {:resource, Article}

    assert Source.canonical_source({:stream, {:relationship, :items}, key: :id}) ==
             {:relationship, :items}

    assert Source.canonical_source({:pubsub, "topic", source: {:assign, :feed}}) ==
             {:assign, :feed}
  end

  test "binding resolves live collection source metadata with default key" do
    binding =
      Binding.resolve(%{
        name: :feed,
        source: {:pubsub, "ash_sdui:feed", [source: {:assign, :seed_feed}, event: :feed_update]},
        many?: true,
        update: :merge
      })

    assert binding.refresh == :subscription
    assert binding.update_strategy == :merge
    assert binding.source_kind == :pubsub
    assert binding.subscription.topic == "ash_sdui:feed"
    assert binding.subscription.event == :feed_update
    assert binding.subscription.key == :id
  end

  test "binding applies collection update strategies and edge cases consistently" do
    base = [%{id: "1", title: "First"}]

    scenarios = [
      {:append, base, %{operation: :append, item: %{id: "2", title: "Second"}}, ["1", "2"]},
      {:prepend, base, %{operation: :prepend, item: %{id: "0", title: "Zero"}}, ["0", "1"]},
      {:replace, base, %{operation: :replace, items: [%{id: "9", title: "Only"}]}, ["9"]},
      {:merge, base, %{operation: :merge, item: %{id: "1", title: "Updated"}}, ["1"]},
      {:remove, [%{id: "1"}, %{id: "2"}], %{operation: :remove, id: "2"}, ["1"]}
    ]

    Enum.each(scenarios, fn {strategy, current, payload, expected_ids} ->
      binding = feed_binding(%{update: strategy})

      assert {:ok, updated, _meta} =
               Binding.apply_update(binding, current, {:ash_sdui_event, :feed_update, payload})

      assert Enum.map(updated, & &1.id) == expected_ids
    end)

    merge_binding = feed_binding(%{update: :merge})

    assert {:ok, merged_missing, _meta} =
             Binding.apply_update(
               merge_binding,
               base,
               {:ash_sdui_event, :feed_update,
                %{operation: :merge, item: %{id: "3", title: "Third"}}}
             )

    assert Enum.map(merged_missing, & &1.id) == ["1", "3"]

    assert {:ok, removed_missing, _meta} =
             Binding.apply_update(
               feed_binding(%{update: :remove}),
               base,
               {:ash_sdui_event, :feed_update, %{operation: :remove, id: "missing"}}
             )

    assert removed_missing == base

    assert {:ok, duplicate_appended, _meta} =
             Binding.apply_update(
               feed_binding(%{update: :append}),
               base,
               {:ash_sdui_event, :feed_update,
                %{operation: :append, item: %{id: "1", title: "Duplicate"}}}
             )

    assert Enum.map(duplicate_appended, & &1.id) == ["1", "1"]

    assert {:ok, duplicate_prepended, _meta} =
             Binding.apply_update(
               feed_binding(%{update: :prepend}),
               base,
               {:ash_sdui_event, :feed_update,
                %{operation: :prepend, item: %{id: "1", title: "Duplicate"}}}
             )

    assert Enum.map(duplicate_prepended, & &1.id) == ["1", "1"]
  end

  test "binding apply_update keeps single-value bindings collection-shaped today" do
    binding =
      Binding.resolve(%{
        name: :record,
        source: {:stream, {:assign, :record}, [event: :feed_update]},
        many?: false,
        update: :merge
      })

    assert {:ok, updated, _meta} =
             Binding.apply_update(
               binding,
               %{id: "1", title: "First"},
               {:ash_sdui_event, :feed_update, %{operation: :merge, item: %{id: "1", title: "Updated"}}}
             )

    assert updated == [%{id: "1", title: "Updated"}]
  end

  test "binding subscription matching covers positive and negative live sources" do
    poll =
      Binding.resolve(%{
        name: :metrics,
        source: {:poll, {:assign, :metrics}, interval: 5_000}
      })

    stream =
      Binding.resolve(%{
        name: :feed,
        source: {:stream, {:assign, :seed_feed}, [event: :feed_update]}
      })

    pubsub =
      Binding.resolve(%{
        name: :activity,
        source: {:pubsub, "ash_sdui:activity", [event: :activity_update]}
      })

    assert Binding.subscription_match?(poll, {:ash_sdui_poll, :metrics})
    refute Binding.subscription_match?(poll, {:ash_sdui_poll, :other})

    assert Binding.subscription_match?(stream, {:ash_sdui_event, :feed_update, %{operation: :append}})
    refute Binding.subscription_match?(stream, {:ash_sdui_event, :other, %{}})

    assert Binding.subscription_match?(pubsub, %{event: :activity_update, payload: %{}})
    refute Binding.subscription_match?(pubsub, %{event: :feed_update, payload: %{}})
  end
end
