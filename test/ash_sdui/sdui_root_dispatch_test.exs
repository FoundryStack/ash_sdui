defmodule AshSDUI.SDUIRootDispatchTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  alias AshSDUI.TestFixtures.SDUIRootPolicyDomain, as: PolicyDomain
  alias AshSDUI.TestFixtures.SDUIRootTenantPost, as: TenantPost

  defmodule MockUserCard do
    use Phoenix.Component

    def render(assigns) do
      ~H"""
      <div class="mock-user-card" data-testid="mock-user-card">
        mock-user-card: <%= inspect(@subject) %>
      </div>
      """
    end
  end

  defmodule RuntimeAwareCard do
    use Phoenix.Component

    def render(assigns) do
      ~H"""
      <div
        class="runtime-aware-card"
        data-testid="runtime-aware-card"
        data-binding={@binding_name}
        data-state={if is_map(@state_slice), do: @state_slice[:state]}
        data-status={@refresh_meta[:status]}
      >
        {List.first(@bound_value || [])[:label]}
      </div>
      """
    end
  end

  setup do
    AshSDUI.Cache.start_link()
    :persistent_term.put({AshSDUI.Registry, :components}, %{})
    Ash.DataLayer.Ets.stop(TenantPost)
    :ok
  end

  describe "dispatch to registered component" do
    test "calls module.render/1 when component is registered" do
      AshSDUI.Registry.register(
        "UserCard@v1",
        MockUserCard,
        %{fragment: "fragment X on User { id }", subject_types: ["User"]}
      )

      tree = %AshSDUI.Renderer.TreeNode{
        id: "1",
        component_name: "UserCard@v1",
        static_props: %{},
        subject_resource: nil,
        subject_id: nil,
        region: :default,
        order: 0,
        children: []
      }

      html = render_component(&AshSDUI.Components.SDUIRoot.render/1, %{tree: tree})
      assert html =~ "mock-user-card"
      refute html =~ "data-sdui-component"
    end

    test "passes correct assigns to component.render/1" do
      defmodule MockWithAsserts do
        use Phoenix.Component

        def render(
              %{subject: nil, props: %{"key" => "value"}, region: :sidebar, children: %{}} =
                assigns
            ) do
          ~H"""
          <div class="assertions-passed"><%= @subject %></div>
          """
        end
      end

      AshSDUI.Registry.register(
        "Test@v1",
        MockWithAsserts,
        %{fragment: "fragment X on Test { id }", subject_types: ["Test"]}
      )

      tree = %AshSDUI.Renderer.TreeNode{
        id: "1",
        component_name: "Test@v1",
        static_props: %{"key" => "value"},
        subject_resource: nil,
        subject_id: nil,
        region: :sidebar,
        order: 0,
        children: []
      }

      html = render_component(&AshSDUI.Components.SDUIRoot.render/1, %{tree: tree})
      assert html =~ "assertions-passed"
    end

    test "passes runtime bindings and state slices to registered components" do
      AshSDUI.Registry.register(
        "RuntimeAware@v1",
        RuntimeAwareCard,
        %{fragment: "fragment X on Test { id }", subject_types: ["Test"]}
      )

      tree =
        %AshSDUI.Renderer.TreeNode{
          id: "runtime-aware",
          component_name: "RuntimeAware@v1",
          static_props: %{},
          subject_resource: nil,
          subject_id: nil,
          region: :default,
          order: 0,
          binding: :metrics,
          state_key: :workflow,
          children: []
        }

      html =
        render_component(&AshSDUI.Components.SDUIRoot.render/1, %{
          tree: tree,
          bindings: %{metrics: [%{label: "Active sessions"}]},
          state: %AshSDUI.View.State{
            refresh: %{metrics: %{status: :ready}},
            workflow: %{state: "review"}
          }
        })

      assert html =~ "runtime-aware-card"
      assert html =~ ~s(data-binding="metrics")
      assert html =~ ~s(data-state="review")
      assert html =~ ~s(data-status="ready")
      assert html =~ "Active sessions"
    end

    test "missing binding and state slices degrade safely" do
      AshSDUI.Registry.register(
        "RuntimeAware@v1",
        RuntimeAwareCard,
        %{fragment: "fragment X on Test { id }", subject_types: ["Test"]}
      )

      tree =
        %AshSDUI.Renderer.TreeNode{
          id: "runtime-missing",
          component_name: "RuntimeAware@v1",
          static_props: %{},
          subject_resource: nil,
          subject_id: nil,
          region: :default,
          order: 0,
          binding: :metrics,
          state_key: :workflow,
          children: []
        }

      html =
        render_component(&AshSDUI.Components.SDUIRoot.render/1, %{
          tree: tree,
          bindings: %{},
          state: %AshSDUI.View.State{}
        })

      assert html =~ "runtime-aware-card"
      assert html =~ ~s(data-binding="metrics")
      refute html =~ "data-status="
      refute html =~ "data-state="
    end
  end

  describe "placeholder for unregistered component" do
    test "renders structural div when component not in registry" do
      tree = %AshSDUI.Renderer.TreeNode{
        id: "1",
        component_name: "Unknown@v1",
        static_props: %{},
        subject_resource: nil,
        subject_id: nil,
        region: :default,
        order: 0,
        children: []
      }

      html = render_component(&AshSDUI.Components.SDUIRoot.render/1, %{tree: tree})
      assert html =~ ~s(data-sdui-component="Unknown@v1")
      assert html =~ ~s(data-sdui-region="default")
    end
  end

  describe "subject resolution" do
    test "resolve/1 returns nil when subject_resource is nil" do
      node = %{subject_resource: nil, subject_id: nil}
      assert nil == AshSDUI.Calculations.ResolveSubject.resolve(node)
    end

    test "resolve/1 returns nil when module cannot be loaded" do
      node = %{subject_resource: "Nonexistent.Resource", subject_id: "some-uuid"}
      assert nil == AshSDUI.Calculations.ResolveSubject.resolve(node)
    end

    test "resolve/2 forwards tenant context to Ash reads" do
      {:ok, post} =
        TenantPost
        |> Ash.Changeset.for_create(:create, %{title: "Context aware", account_id: "tenant-a"})
        |> Ash.create(tenant: "tenant-a")

      node = %{subject_resource: to_string(TenantPost), subject_id: to_string(post.id)}

      assert nil == AshSDUI.Calculations.ResolveSubject.resolve(node, domain: PolicyDomain)

      assert %TenantPost{id: resolved_id} =
               AshSDUI.Calculations.ResolveSubject.resolve(node,
                 domain: PolicyDomain,
                 context: %{tenant: "tenant-a"}
               )

      assert resolved_id == post.id
    end
  end

  describe "recursive rendering" do
    test "renders nested children from tree" do
      AshSDUI.Registry.register(
        "Parent@v1",
        MockUserCard,
        %{fragment: "fragment X on Test { id }", subject_types: ["Test"]}
      )

      AshSDUI.Registry.register(
        "Child@v1",
        MockUserCard,
        %{fragment: "fragment X on Test { id }", subject_types: ["Test"]}
      )

      child1 = %AshSDUI.Renderer.TreeNode{
        id: "c1",
        component_name: "Child@v1",
        static_props: %{},
        subject_resource: nil,
        subject_id: nil,
        region: :sidebar,
        order: 0,
        children: []
      }

      child2 = %AshSDUI.Renderer.TreeNode{
        id: "c2",
        component_name: "Child@v1",
        static_props: %{},
        subject_resource: nil,
        subject_id: nil,
        region: :main,
        order: 0,
        children: []
      }

      parent = %AshSDUI.Renderer.TreeNode{
        id: "p1",
        component_name: "Parent@v1",
        static_props: %{},
        subject_resource: nil,
        subject_id: nil,
        region: :default,
        order: 0,
        children: [child1, child2]
      }

      html = render_component(&AshSDUI.Components.SDUIRoot.render/1, %{tree: parent})
      # Should contain multiple "mock-user-card" divs from the parent and both children
      count = Regex.scan(~r/mock-user-card/, html) |> length()
      assert count >= 2
    end
  end
end
