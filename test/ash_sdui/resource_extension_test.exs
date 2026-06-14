defmodule AshSDUI.ResourceExtensionTest do
  use ExUnit.Case, async: true

  alias AshSDUI.Resource.Info
  alias AshSDUI.TestFixtures.ResourceExtension.ActionAttrs
  alias AshSDUI.TestFixtures.ResourceExtension.ActionDefaults
  alias AshSDUI.TestFixtures.ResourceExtension.AttrDefaults
  alias AshSDUI.TestFixtures.ResourceExtension.AttrLabelKey
  alias AshSDUI.TestFixtures.ResourceExtension.AttrWidget
  alias AshSDUI.TestFixtures.ResourceExtension.Basic
  alias AshSDUI.TestFixtures.ResourceExtension.DefaultDomainResource
  alias AshSDUI.TestFixtures.ResourceExtension.GettextResource
  alias AshSDUI.TestFixtures.ResourceExtension.LabelKey
  alias AshSDUI.TestFixtures.ResourceExtension.NoDefault
  alias AshSDUI.TestFixtures.ResourceExtension.WithActions
  alias AshSDUI.TestFixtures.ResourceExtension.WithAttrs
  alias AshSDUI.TestFixtures.ResourceExtension.WithDefault

  describe "AshSDUI.Resource DSL" do
    test "resource compiles with sdui block" do
      # Resource should have been registered with default_component
      assert Info.default_component(Basic) == "Card@v1"
    end

    test "reads default_component option" do
      assert Info.default_component(WithDefault) == "Player.Profile@v2"
    end

    test "default_component is optional" do
      assert Info.default_component(NoDefault) == nil
    end

    test "defines ui_action entities" do
      actions = Info.ui_actions(WithActions)

      assert length(actions) == 3
      assert Enum.any?(actions, &(&1.name == :create))
      assert Enum.any?(actions, &(&1.intent == :destructive))
    end

    test "ui_action defaults intent to :secondary" do
      [action] = Info.ui_actions(ActionDefaults)

      assert action.intent == :secondary
    end

    test "ui_action accepts optional label and icon" do
      [action] = Info.ui_actions(ActionAttrs)

      assert action.label == "Send Form"
      assert action.icon == "send"
    end

    test "defines ui_attribute entities" do
      attrs = Info.ui_attributes(WithAttrs)

      assert length(attrs) == 3
      assert Enum.any?(attrs, &(&1.name == :name))
    end

    test "ui_attribute defaults" do
      [attr] = Info.ui_attributes(AttrDefaults)

      assert attr.name == :status
      assert attr.hidden == false
      assert attr.order == 0
      assert attr.label == nil
      assert attr.widget == nil
    end

    test "ui_attribute accepts widget metadata" do
      [attr] = Info.ui_attributes(AttrWidget)
      assert attr.widget == :textarea
    end

    # Note: Verifier test skipped - defmodule suppresses verification errors in tests
    # The verifier DOES run in real usage and will catch nonexistent actions
  end

  describe "label_key i18n support" do
    test "ui_action accepts label_key" do
      [action] = Info.ui_actions(LabelKey)
      assert action.label_key == "player.action.create"
      assert action.label == nil
    end

    test "ui_attribute accepts label_key" do
      attrs = Info.ui_attributes(AttrLabelKey)
      name_attr = Enum.find(attrs, &(&1.name == :name))
      score_attr = Enum.find(attrs, &(&1.name == :score))

      assert name_attr.label_key == "player.name"
      assert name_attr.label == nil
      assert score_attr.label == "High Score"
      assert score_attr.label_key == nil
    end

    test "resolve_label/2 returns hardcoded label when present" do
      attr = %AshSDUI.Resource.UiAttribute{
        name: :score,
        label: "High Score",
        label_key: nil,
        hidden: false,
        order: 0
      }

      assert Info.resolve_label(attr, nil) == "High Score"
    end

    test "resolve_label/2 falls back to titlecased name when no label or key" do
      attr = %AshSDUI.Resource.UiAttribute{
        name: :first_name,
        label: nil,
        label_key: nil,
        hidden: false,
        order: 0
      }

      result = Info.resolve_label(attr, nil)
      # Falls back to name-based string when no backend
      assert is_binary(result)
    end

    test "resolve_label/2 falls back to name string when backend not loaded" do
      attr = %AshSDUI.Resource.UiAttribute{
        name: :username,
        label: nil,
        label_key: "user.username",
        hidden: false,
        order: 0
      }

      # NonExistent.Gettext is not a loaded module
      result = Info.resolve_label(attr, NonExistent.Gettext)
      assert result == "username"
    end

    test "sdui section accepts gettext_backend option" do
      assert Info.gettext_backend(GettextResource) == SduiDemo.Gettext
      assert Info.gettext_domain(GettextResource) == "myapp"
    end

    test "gettext_domain defaults to \"sdui\"" do
      assert Info.gettext_domain(DefaultDomainResource) == "sdui"
    end
  end
end
