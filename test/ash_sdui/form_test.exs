defmodule AshSDUI.FormTest do
  use ExUnit.Case, async: false
  import Phoenix.LiveViewTest

  alias AshSDUI.Components.FieldInput
  alias AshSDUI.TestFixtures.ComponentFormResource
  alias AshSDUI.TestFixtures.FormResource
  alias AshSDUI.TestFixtures.RelationshipArticle
  alias AshSDUI.TestFixtures.RelationshipArticleTag
  alias AshSDUI.TestFixtures.RelationshipArticleUI
  alias AshSDUI.TestFixtures.RelationshipAuthor
  alias AshSDUI.TestFixtures.RelationshipComment
  alias AshSDUI.TestFixtures.RelationshipCover
  alias AshSDUI.TestFixtures.RelationshipSelectDomain
  alias AshSDUI.TestFixtures.RelationshipTag

  setup do
    for resource <- [
          RelationshipArticle,
          RelationshipArticleTag,
          RelationshipAuthor,
          RelationshipCover,
          RelationshipComment,
          RelationshipTag
        ] do
      Ash.DataLayer.Ets.stop(resource)
    end

    :ok
  end

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

  test "fields/2 infers relationship selectors across relation kinds" do
    fields = AshSDUI.Form.fields(RelationshipArticleUI, :create)

    assert Enum.find(fields, &(&1.name == :author_id)).widget == :select
    assert Enum.find(fields, &(&1.name == :author_id)).relationship == :author
    assert Enum.find(fields, &(&1.name == :cover_id)).widget == :select
    assert Enum.find(fields, &(&1.name == :cover_id)).relationship == :cover
    assert Enum.find(fields, &(&1.name == :comment_ids)).widget == :multiselect
    assert Enum.find(fields, &(&1.name == :comment_ids)).relationship == :comments
    assert Enum.find(fields, &(&1.name == :tag_ids)).widget == :multiselect
    assert Enum.find(fields, &(&1.name == :tag_ids)).relationship == :tags
  end

  test "hydrate/4 loads relationship selector options" do
    author =
      Ash.create!(RelationshipAuthor, %{username: "author-one"},
        action: :create,
        domain: RelationshipSelectDomain
      )

    cover =
      Ash.create!(RelationshipCover, %{title: "Feature Cover"},
        action: :create,
        domain: RelationshipSelectDomain
      )

    comment =
      Ash.create!(RelationshipComment, %{body: "First comment"},
        action: :create,
        domain: RelationshipSelectDomain
      )

    tag =
      Ash.create!(RelationshipTag, %{name: "news"},
        action: :create,
        domain: RelationshipSelectDomain
      )

    fields =
      AshSDUI.Form.hydrate(
        RelationshipArticleUI,
        :create,
        AshSDUI.Form.fields(RelationshipArticleUI, :create),
        domain: RelationshipSelectDomain
      )

    assert Enum.find(fields, &(&1.name == :author_id)).options == [{"author-one", author.id}]
    assert Enum.find(fields, &(&1.name == :cover_id)).options == [{"Feature Cover", cover.id}]

    assert Enum.find(fields, &(&1.name == :comment_ids)).options == [
             {"First comment", comment.id}
           ]

    assert Enum.find(fields, &(&1.name == :tag_ids)).options == [{"news", tag.id}]
  end

  test "initial_params/2 derives edit defaults for relationship arguments" do
    author =
      Ash.create!(RelationshipAuthor, %{username: "editor"},
        action: :create,
        domain: RelationshipSelectDomain
      )

    cover =
      Ash.create!(RelationshipCover, %{title: "Hero"},
        action: :create,
        domain: RelationshipSelectDomain
      )

    comment =
      Ash.create!(RelationshipComment, %{body: "Selected"},
        action: :create,
        domain: RelationshipSelectDomain
      )

    tag =
      Ash.create!(RelationshipTag, %{name: "featured"},
        action: :create,
        domain: RelationshipSelectDomain
      )

    article =
      Ash.create!(
        RelationshipArticle,
        %{
          title: "Article",
          author_id: author.id,
          cover_id: cover.id,
          comment_ids: [comment.id],
          tag_ids: [tag.id]
        },
        action: :create,
        domain: RelationshipSelectDomain
      )
      |> Ash.load!([:cover, :comments, :tags], domain: RelationshipSelectDomain)

    fields =
      AshSDUI.Form.hydrate(
        RelationshipArticleUI,
        :update,
        AshSDUI.Form.fields(RelationshipArticleUI, :update),
        domain: RelationshipSelectDomain
      )

    assert AshSDUI.Form.initial_params(article, fields) == %{
             "cover_id" => cover.id,
             "comment_ids" => [comment.id],
             "tag_ids" => [tag.id]
           }
  end

  test "prepare_params/2 fills missing multiselect fields with empty lists" do
    fields = AshSDUI.Form.fields(RelationshipArticleUI, :update)

    assert AshSDUI.Form.prepare_params(%{"title" => "Article"}, fields) == %{
             "title" => "Article",
             "comment_ids" => [],
             "tag_ids" => []
           }
  end

  test "field input renders generated select and multiselect widgets" do
    form =
      Phoenix.Component.to_form(
        %{"author_id" => "author-1", "comment_ids" => ["comment-1"]},
        as: "article"
      )

    select_html =
      render_component(&FieldInput.render/1, %{
        form: form,
        field: %{
          name: :author_id,
          widget: :select,
          prompt: "Choose author",
          options: [{"Author One", "author-1"}]
        }
      })

    multiselect_html =
      render_component(&FieldInput.render/1, %{
        form: form,
        field: %{
          name: :comment_ids,
          widget: :multiselect,
          options: [{"Comment One", "comment-1"}]
        }
      })

    assert select_html =~ ~s(<select)
    assert select_html =~ ~s(<option value="">Choose author</option>)
    assert select_html =~ ~s(selected value="author-1")
    assert multiselect_html =~ ~s(name="article[comment_ids][]")
    assert multiselect_html =~ ~s(selected value="comment-1")
  end
end
