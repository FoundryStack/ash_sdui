defmodule AshSDUI.ScreenTest do
  use ExUnit.Case, async: false

  alias AshSDUI.Context
  alias AshSDUI.Layout
  alias AshSDUI.Screen
  alias AshSDUI.TestFixtures.ScreenArticle, as: Article
  alias AshSDUI.TestFixtures.ScreenArticleUI, as: ArticleUI

  defmodule CompactRecipe do
    @behaviour AshSDUI.LayoutRecipe

    @impl true
    def to_layout(%Screen{} = screen, _opts) do
      %Layout.Node{
        id: :compact_root,
        component: "App.CompactScreen@v1",
        region: :default,
        order: 0,
        static_props: %{mode: screen.mode, field_names: Enum.map(screen.fields, & &1.name)},
        children: []
      }
    end
  end

  test "resolve/3 derives a generic screen from resource metadata" do
    assert {:ok, screen} = Screen.resolve(ArticleUI, :new)

    assert screen.resource == Article
    assert screen.resource_ui == ArticleUI
    assert screen.mode == :new
    assert screen.action == :create
    assert screen.recipe == :form

    assert Enum.map(screen.fields, & &1.name) == [:title, :body]
    assert Enum.find(screen.fields, &(&1.name == :body)).widget == :textarea

    assert Enum.map(screen.actions, & &1.name) == [:create]
    assert Enum.find(screen.actions, &(&1.name == :create)).label == "New Article"
    assert Enum.find(screen.actions, &(&1.name == :create)).placement == :toolbar
    assert screen.assigns.title == nil
  end

  test "context variant resolvers can transform screens without hardcoded roles" do
    context = Context.new(audience: :customer, device: :mobile)

    resolver = fn screen, %Context{audience: :customer} ->
      %{
        screen
        | recipe: :compact,
          fields: Enum.reject(screen.fields, &(&1.name == :internal_notes))
      }
    end

    assert {:ok, screen} =
             Screen.resolve(Article, :show,
               context: context,
               variant_resolvers: [resolver],
               recipe: :detail
             )

    assert screen.context.audience == :customer
    assert screen.context.device == :mobile
    assert screen.recipe == :compact
    refute Enum.any?(screen.fields, &(&1.name == :internal_notes))
  end

  test "screen metadata and field visibility shape collection screens" do
    assert {:ok, screen} = Screen.resolve(ArticleUI, :index)

    assert screen.action == :read
    assert screen.recipe == :collection
    assert screen.assigns.title == "Articles"
    assert Enum.map(screen.fields, & &1.name) == [:title]
  end

  test "actor context enables actor-required actions" do
    context = Context.new(actor: %{id: "user-1"})

    assert {:ok, screen} = Screen.resolve(ArticleUI, :show, context: context)

    assert Enum.map(screen.actions, & &1.name) == [:create, :update]
    assert Enum.find(screen.actions, &(&1.name == :update)).to == "/articles/:id/edit"
  end

  test "resolve/3 applies field and action overrides before recipes render" do
    assert {:ok, screen} =
             Screen.resolve(ArticleUI, :show,
               field_overrides: %{
                 title: %{label: "Headline"},
                 internal_notes: false
               },
               action_overrides: %{
                 create: %{label: "Compose", placement: :row},
                 update: false
               }
             )

    assert Enum.map(screen.fields, & &1.name) == [:title, :body]
    assert Enum.find(screen.fields, &(&1.name == :title)).label == "Headline"
    assert Enum.map(screen.actions, & &1.name) == [:create]
    assert Enum.find(screen.actions, &(&1.name == :create)).label == "Compose"
    assert Enum.find(screen.actions, &(&1.name == :create)).placement == :row
  end

  test "recipe_overrides provide a single customization surface for built-in recipes" do
    assert {:ok, screen} =
             Screen.resolve(ArticleUI, :index,
               recipe_overrides: [
                 title: "Editorial Articles",
                 empty_state: [title: "No articles yet", body: "Publish the first piece."],
                 fields: %{title: %{label: "Headline"}},
                 actions: %{create: %{label: "Compose", placement: :row}},
                 screen: [component: "App.ArticleScreen@v1", props: %{variant: :editorial}],
                 toolbar: [props: %{class: "justify-start"}],
                 content: [component: "App.ArticleCards@v1", props: %{class: "shadow-sm"}]
               ]
             )

    assert screen.assigns.title == "Editorial Articles"
    assert screen.assigns.empty_state == "No articles yet"
    assert screen.assigns.empty_state_body == "Publish the first piece."
    assert Enum.find(screen.fields, &(&1.name == :title)).label == "Headline"
    assert Enum.find(screen.actions, &(&1.name == :create)).label == "Compose"
    assert Enum.find(screen.actions, &(&1.name == :create)).placement == :row

    assert %Layout.Node{} = node = Screen.to_layout!(screen)
    assert node.component == "App.ArticleScreen@v1"
    assert node.static_props.title == "Editorial Articles"
    assert node.static_props.variant == :editorial

    assert Enum.find(node.children, &(&1.region == :toolbar)).static_props.class ==
             "justify-start"

    assert Enum.find(node.children, &(&1.region == :content)).component ==
             "App.ArticleCards@v1"

    assert Enum.find(node.children, &(&1.region == :content)).static_props.empty_body ==
             "Publish the first piece."
  end

  test "recipe_overrides can hide the toolbar in the generic recipe" do
    assert {:ok, screen} = Screen.resolve(ArticleUI, :show, recipe_overrides: [toolbar: false])
    assert %Layout.Node{} = node = Screen.to_layout!(screen)

    assert Enum.map(node.children, & &1.region) == [:content]
  end

  test "to_layout/2 uses the registered recipe implementation" do
    AshSDUI.LayoutRecipe.Registry.register(:compact, CompactRecipe)

    assert {:ok, screen} = Screen.resolve(ArticleUI, :show, recipe: :compact)
    assert %Layout.Node{} = node = Screen.to_layout!(screen)

    assert node.component == "App.CompactScreen@v1"
    assert node.static_props.field_names == [:title, :body, :internal_notes]
  end

  test "default recipe creates a generic layout tree with stable regions" do
    assert {:ok, screen} = Screen.resolve(ArticleUI, :index)
    assert %Layout.Node{} = node = Screen.to_layout!(screen)

    assert node.component == "AshSDUI.GenericScreen@v1"
    assert Enum.map(node.children, & &1.region) == [:toolbar, :content]

    assert Enum.find(node.children, &(&1.region == :content)).component ==
             "AshSDUI.ResourceCollection@v1"
  end
end
