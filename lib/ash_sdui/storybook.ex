defmodule AshSDUI.Storybook do
  @moduledoc """
  Storybook integration for AshSDUI components.

  Requires optional dependency `phoenix_storybook ~> 1.2`.

  ## Usage

      defmodule MyAppWeb.Storybook.PlayerCard do
        use AshSDUI.Storybook, resource: MyApp.Player
      end

  This generates a story pointing at `SDUIRoot` with a mock tree derived from the resource's
  `default_component` annotation.

  ## Requirements

  - Resource must have `default_component` set in its `sdui` block, or pass `:component_name`
  - `phoenix_storybook` must be available as a dependency
  """

  defmacro __using__(opts) do
    quote do
      if Code.ensure_loaded?(PhoenixStorybook.Story) do
        use PhoenixStorybook.Story, :component
        alias PhoenixStorybook.Stories.Variation

        def function, do: &AshSDUI.Components.SDUIRoot.render/1

        def variations do
          resource = unquote(Keyword.fetch!(opts, :resource))
          base_tree = AshSDUI.Mock.from_resource(resource, unquote(opts))

          [
            %Variation{
              id: :default,
              attributes: %{tree: base_tree}
            }
          ]
        end
      else
        raise CompileError,
          file: __ENV__.file,
          line: __ENV__.line,
          description:
            "phoenix_storybook is required to use AshSDUI.Storybook. Add `{:phoenix_storybook, \"~> 1.2\"}` to your dependencies."
      end
    end
  end
end
