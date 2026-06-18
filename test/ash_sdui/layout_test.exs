defmodule AshSDUI.LayoutTest do
  use ExUnit.Case, async: false

  alias AshSDUI.Layout
  alias AshSDUI.Layout.Builder
  alias AshSDUI.TestFixtures.CustomNodeResource
  alias AshSDUI.TestFixtures.TestLayoutResource
  alias AshSDUI.UINode

  setup_all do
    AshSDUI.Test.TestLayout.init_layouts()
    :ok
  end

  setup do
    Ash.DataLayer.Ets.stop(UINode)
    Ash.DataLayer.Ets.stop(UINode.Version)
    Ash.DataLayer.Ets.stop(CustomNodeResource)

    :ok
  end

  describe "code-based layout registration" do
    test "layout is registered and retrievable" do
      assert {:ok, layout} = Layout.get("test-dashboard")
      assert layout.name == "test-dashboard"
    end

    test "missing layout returns error" do
      assert {:error, :not_found} = Layout.get("nonexistent-layout")
    end

    test "root node has correct component" do
      {:ok, layout} = Layout.get("test-dashboard")
      assert layout.root.component == "Layouts.TwoColumn@v1"
    end

    test "nested nodes produce correct parent-child relationships" do
      {:ok, layout} = Layout.get("test-dashboard")
      root = layout.root
      assert length(root.children) == 2
      child_ids = Enum.map(root.children, & &1.id)
      assert :header in child_ids
      assert :body in child_ids
    end

    test "region and order options are preserved" do
      {:ok, layout} = Layout.get("test-dashboard")
      header = Enum.find(layout.root.children, &(&1.id == :header))
      assert header.region == :sidebar
      assert header.order == 0
    end

    test "node runtime metadata is preserved for code-defined layouts" do
      root =
        Builder.node("Layouts.Runtime@v1",
          binding: :metrics,
          refresh: :manual,
          variant: :info,
          state_key: :workflow
        )

      Layout.register("runtime-metadata-layout", root)

      assert {:ok, layout} = Layout.fetch("runtime-metadata-layout", source: :registered)
      assert layout.root.binding == :metrics
      assert layout.root.refresh == :manual
      assert layout.root.variant == :info
      assert layout.root.state_key == :workflow
    end

    test "all/0 returns registered layouts" do
      names = Layout.all() |> Enum.map(& &1.name)
      assert "test-dashboard" in names
    end

    test "fetch/2 returns registered layouts by default" do
      assert {:ok, layout} = Layout.fetch("test-dashboard")
      assert layout.name == "test-dashboard"
      assert layout.root.component == "Layouts.TwoColumn@v1"
    end
  end

  describe "stored layout operations" do
    test "save/3 stores a tree and fetch/2 returns it as a layout definition" do
      root =
        Builder.node("Layouts.TwoColumn@v1",
          children: [
            Builder.node("UserProfile.Header@v1", region: :sidebar, subject_id: "first"),
            Builder.node("Betting.ActiveBets@v1", region: :main, subject_id: "bet-1", order: 1)
          ]
        )

      assert {:ok, records} = Layout.save("stored-dashboard", root)
      assert length(records) == 3

      assert {:ok, layout} = Layout.fetch("stored-dashboard", source: :stored, status: :draft)
      assert layout.name == "stored-dashboard"
      assert layout.root.component == "Layouts.TwoColumn@v1"
      assert Enum.map(layout.root.children, & &1.region) == [:sidebar, :main]
    end

    test "fetch/2 falls back to stored layouts when no registered layout exists" do
      root = Builder.node("Stored.Only@v1")

      assert {:ok, _records} = Layout.save("stored-only", root, status: :published)
      assert {:ok, layout} = Layout.fetch("stored-only")

      assert layout.root.component == "Stored.Only@v1"
    end

    test "fetch/2 prefers registered layouts over stored ones when source is :any" do
      Layout.register("shared-layout-name", Builder.node("Registered.Root@v1"))

      assert {:ok, _records} =
               Layout.save("shared-layout-name", Builder.node("Stored.Root@v1"),
                 status: :published
               )

      assert {:ok, layout} = Layout.fetch("shared-layout-name")
      assert layout.root.component == "Registered.Root@v1"

      assert {:ok, stored_layout} = Layout.fetch("shared-layout-name", source: :stored)
      assert stored_layout.root.component == "Stored.Root@v1"
    end

    test "publish/2 marks stored nodes as published" do
      root = Builder.node("Stored.Publishable@v1")

      assert {:ok, _records} = Layout.save("publishable-layout", root)
      assert {:ok, published} = Layout.publish("publishable-layout")
      assert Enum.all?(published, &(&1.status == :published))
      assert {:ok, _layout} = Layout.fetch("publishable-layout", source: :stored)
    end

    test "save/3 and fetch/2 support a compatible custom node_resource" do
      root =
        Builder.node("Custom.Root@v1",
          children: [Builder.node("Custom.Child@v1", region: :sidebar, subject_id: "user-1")]
        )

      opts = [node_resource: CustomNodeResource, status: :published]

      assert {:ok, records} = Layout.save("custom-node-layout", root, opts)
      assert length(records) == 2

      assert {:ok, layout} =
               Layout.fetch("custom-node-layout",
                 source: :stored,
                 node_resource: CustomNodeResource
               )

      assert layout.root.component == "Custom.Root@v1"
      assert Enum.map(layout.root.children, & &1.component) == ["Custom.Child@v1"]
    end

    test "save/3 and fetch/2 preserve node runtime metadata through stored layouts" do
      root =
        Builder.node("Stored.Runtime@v1",
          binding: :feed,
          refresh: :subscription,
          variant: :warning,
          state_key: [:workflow, :state]
        )

      assert {:ok, _records} = Layout.save("stored-runtime-metadata", root, status: :published)
      assert {:ok, layout} = Layout.fetch("stored-runtime-metadata", source: :stored)

      assert layout.root.binding == :feed
      assert layout.root.refresh == :subscription
      assert layout.root.variant == :warning
      assert layout.root.state_key == [:workflow, :state]
      assert layout.root.static_props == %{}
    end
  end

  test "builder creates resource-backed node with default component" do
    node = Builder.resource(TestLayoutResource, subject_id: "abc-123", region: :main)

    assert node.component == "Test.Card@v1"
    assert node.subject_resource == to_string(TestLayoutResource)
    assert node.subject_id == "abc-123"
    assert node.region == :main
  end
end
