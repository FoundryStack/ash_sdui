defmodule SduiDemoWeb.Storybook do
  @behaviour PhoenixStorybook.BackendBehaviour

  alias PhoenixStorybook.{Entries, ExsCompiler}
  alias PhoenixStorybook.Stories.StoryValidator

  @moduledoc false

  @opts [
    otp_app: :sdui_demo,
    css_path: "/assets/app.css",
    content_path: Path.expand("../../priv/storybook", __DIR__)
  ]
  @content_path Keyword.fetch!(@opts, :content_path)
  @content_tree Entries.content_tree(@opts)
  @flat_list Entries.flat_list(@content_tree)
  @leaves Entries.leaves(@content_tree)
  @index_pattern Path.join(@content_path, "**/*#{Entries.index_file_suffix()}")
  @components_pattern Path.join(@content_path, "**/*")
  @index_paths Path.wildcard(@index_pattern)
  @paths_hash @components_pattern |> Path.wildcard() |> :erlang.md5()

  for index_path <- @index_paths do
    @external_resource index_path
  end

  @impl PhoenixStorybook.BackendBehaviour
  def config(key, default \\ nil) do
    Keyword.get(@opts, key, default)
  end

  @impl PhoenixStorybook.BackendBehaviour
  def content_tree, do: @content_tree

  @impl PhoenixStorybook.BackendBehaviour
  def leaves, do: @leaves

  @impl PhoenixStorybook.BackendBehaviour
  def flat_list, do: @flat_list

  @impl PhoenixStorybook.BackendBehaviour
  def find_entry_by_path(path)

  for entry <- @flat_list do
    def find_entry_by_path(unquote(entry.path)), do: unquote(Macro.escape(entry))
  end

  def find_entry_by_path(_), do: nil

  @impl PhoenixStorybook.BackendBehaviour
  def storybook_path(story_module) do
    if Code.ensure_loaded?(story_module) do
      story_module.__file_path__()
      |> String.replace_prefix(@content_path, "")
      |> String.replace_suffix(Entries.story_file_suffix(), "")
    end
  end

  def __mix_recompile__? do
    Path.wildcard(@components_pattern) |> :erlang.md5() != @paths_hash
  end

  if Mix.env() == :dev do
    def load_story(story_path) do
      story_path =
        story_path
        |> String.replace_prefix("/", "")
        |> Kernel.<>(Entries.story_file_suffix())

      case ExsCompiler.compile_exs(story_path, @content_path, @opts) do
        {:ok, story} -> StoryValidator.validate(story)
        {:error, message, exception} -> {:error, message, exception}
      end
    end
  else
    for story_entry <- @leaves do
      story_name = String.replace_prefix(story_entry.path, "/", "")
      story_path = story_name <> Entries.story_file_suffix()

      story =
        story_path
        |> ExsCompiler.compile_exs!(@content_path, @opts)
        |> StoryValidator.validate!()

      @external_resource Path.join(@content_path, story_path)
      def load_story(unquote(story_name)), do: {:ok, unquote(story)}
    end

    def load_story(_), do: {:error, :not_found}
  end

  # PhoenixStorybook hashes configured assets while compiling the backend module.
  # This demo lets Phoenix watchers build app.css after boot, so we resolve the
  # hash at runtime instead of warning on every fresh compile.
  def asset_hash(asset) when asset in [:css_path, :js_path] do
    asset
    |> config()
    |> asset_digest()
  end

  def asset_hash(_), do: nil

  defp asset_digest(nil), do: nil

  defp asset_digest(asset_path) do
    case File.read(asset_full_path(asset_path)) do
      {:ok, content} ->
        Base.encode16(:crypto.hash(:md5, content), case: :lower)

      _ ->
        nil
    end
  end

  defp asset_full_path(asset_path) do
    :sdui_demo
    |> :code.priv_dir()
    |> to_string()
    |> Path.join("static")
    |> Path.join(String.trim_leading(asset_path, "/"))
  end
end
