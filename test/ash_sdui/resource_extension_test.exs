defmodule AshSDUI.ResourceExtensionTest do
  use ExUnit.Case, async: true

  alias AshSDUI.Resource.Info

  describe "AshSDUI.Resource DSL" do
    test "resource compiles with sdui block" do
      defmodule TestResource do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        sdui do
          default_component "Card@v1"
        end
      end

      # Resource should have been registered with default_component
      assert Info.default_component(TestResource) == "Card@v1"
    end

    test "reads default_component option" do
      defmodule TestResourceWithDefault do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        sdui do
          default_component "Player.Profile@v2"
        end
      end

      assert Info.default_component(TestResourceWithDefault) == "Player.Profile@v2"
    end

    test "default_component is optional" do
      defmodule TestResourceNoDefault do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        sdui do
        end
      end

      assert Info.default_component(TestResourceNoDefault) == nil
    end

    test "defines ui_action entities" do
      defmodule TestResourceWithActions do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        attributes do
          attribute :id, :uuid, primary_key?: true, default: &Ecto.UUID.generate/0, allow_nil?: false
        end

        actions do
          action :create
          action :update
          action :delete
        end

        sdui do
          ui_action :create, intent: :primary, label: "New Player", icon: "plus"
          ui_action :update, intent: :secondary
          ui_action :delete, intent: :destructive, icon: "trash"
        end
      end

      actions = Info.ui_actions(TestResourceWithActions)

      assert length(actions) == 3
      assert Enum.any?(actions, &(&1.name == :create))
      assert Enum.any?(actions, &(&1.intent == :destructive))
    end

    test "ui_action defaults intent to :secondary" do
      defmodule TestResourceActionDefaults do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        attributes do
          attribute :id, :uuid, primary_key?: true, default: &Ecto.UUID.generate/0, allow_nil?: false
        end

        actions do
          action :view
        end

        sdui do
          ui_action :view
        end
      end

      [action] = Info.ui_actions(TestResourceActionDefaults)

      assert action.intent == :secondary
    end

    test "ui_action accepts optional label and icon" do
      defmodule TestResourceActionAttrs do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        attributes do
          attribute :id, :uuid, primary_key?: true, default: &Ecto.UUID.generate/0, allow_nil?: false
        end

        actions do
          action :submit
        end

        sdui do
          ui_action :submit, label: "Send Form", icon: "send"
        end
      end

      [action] = Info.ui_actions(TestResourceActionAttrs)

      assert action.label == "Send Form"
      assert action.icon == "send"
    end

    test "defines ui_attribute entities" do
      defmodule TestResourceWithAttrs do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        sdui do
          ui_attribute :name, label: "Player Name", order: 1
          ui_attribute :email, label: "Email Address", order: 2, hidden: true
          ui_attribute :created_at
        end
      end

      attrs = Info.ui_attributes(TestResourceWithAttrs)

      assert length(attrs) == 3
      assert Enum.any?(attrs, &(&1.name == :name))
    end

    test "ui_attribute defaults" do
      defmodule TestResourceAttrDefaults do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        sdui do
          ui_attribute :status
        end
      end

      [attr] = Info.ui_attributes(TestResourceAttrDefaults)

      assert attr.name == :status
      assert attr.hidden == false
      assert attr.order == 0
      assert attr.label == nil
    end

    # Note: Verifier test skipped - defmodule suppresses verification errors in tests
    # The verifier DOES run in real usage and will catch nonexistent actions
  end
end
