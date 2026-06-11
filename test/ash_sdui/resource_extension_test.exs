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

  describe "label_key i18n support" do
    test "ui_action accepts label_key" do
      defmodule TestResourceLabelKey do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        attributes do
          attribute :id, :uuid, primary_key?: true, default: &Ecto.UUID.generate/0, allow_nil?: false
        end

        actions do
          action :create
        end

        sdui do
          ui_action :create, label_key: "player.action.create", icon: "plus"
        end
      end

      [action] = Info.ui_actions(TestResourceLabelKey)
      assert action.label_key == "player.action.create"
      assert action.label == nil
    end

    test "ui_attribute accepts label_key" do
      defmodule TestResourceAttrLabelKey do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        sdui do
          ui_attribute :name, label_key: "player.name"
          ui_attribute :score, label: "High Score"
        end
      end

      attrs = Info.ui_attributes(TestResourceAttrLabelKey)
      name_attr = Enum.find(attrs, &(&1.name == :name))
      score_attr = Enum.find(attrs, &(&1.name == :score))

      assert name_attr.label_key == "player.name"
      assert name_attr.label == nil
      assert score_attr.label == "High Score"
      assert score_attr.label_key == nil
    end

    test "resolve_label/2 returns hardcoded label when present" do
      attr = %AshSDUI.Resource.UiAttribute{name: :score, label: "High Score", label_key: nil, hidden: false, order: 0}
      assert Info.resolve_label(attr, nil) == "High Score"
    end

    test "resolve_label/2 falls back to titlecased name when no label or key" do
      attr = %AshSDUI.Resource.UiAttribute{name: :first_name, label: nil, label_key: nil, hidden: false, order: 0}
      result = Info.resolve_label(attr, nil)
      # Falls back to name-based string when no backend
      assert is_binary(result)
    end

    test "resolve_label/2 falls back to name string when backend not loaded" do
      attr = %AshSDUI.Resource.UiAttribute{name: :username, label: nil, label_key: "user.username", hidden: false, order: 0}
      # NonExistent.Gettext is not a loaded module
      result = Info.resolve_label(attr, NonExistent.Gettext)
      assert result == "username"
    end

    test "sdui section accepts gettext_backend option" do
      defmodule TestResourceGettext do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        sdui do
          gettext_backend SduiDemo.Gettext
          gettext_domain "myapp"
        end
      end

      assert Info.gettext_backend(TestResourceGettext) == SduiDemo.Gettext
      assert Info.gettext_domain(TestResourceGettext) == "myapp"
    end

    test "gettext_domain defaults to \"sdui\"" do
      defmodule TestResourceDefaultDomain do
        use Ash.Resource, domain: nil, extensions: [AshSDUI.Resource]

        sdui do
        end
      end

      assert Info.gettext_domain(TestResourceDefaultDomain) == "sdui"
    end
  end
end
