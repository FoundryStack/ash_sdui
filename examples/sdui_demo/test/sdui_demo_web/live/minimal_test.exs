defmodule SduiDemoWeb.Live.MinimalTest do
  use ExUnit.Case, async: false

  @expected_components ~w(
    UserCard@v1
    EditorialPostsPage@v1
    Layouts.TwoColumnLayout@v1
    PostCard@v1
    CommentItem@v1
  )

  test "persistent_term is populated with all components" do
    key = {AshSDUI.Registry, :components}

    map =
      case :persistent_term.get(key, nil) do
        nil -> flunk("persistent_term not populated")
        m -> m
      end

    for name <- @expected_components do
      assert name in Map.keys(map), "Expected component #{inspect(name)} to be registered"
    end
  end

  test "registry lookup works for all components" do
    for name <- @expected_components do
      assert {:ok, _entry} = AshSDUI.Registry.lookup(name),
             "Expected lookup to succeed for #{inspect(name)}"
    end
  end
end
