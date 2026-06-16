defmodule AshSDUI.Storybook do
  @moduledoc """
  Storybook integration for AshSDUI components.

  Requires optional dependency `phoenix_storybook ~> 1.2`.

  ## Usage

      defmodule MyAppWeb.Storybook.PlayerCard do
        use AshSDUI.Storybook, ui: MyApp.UI.PlayerUI, view: :index
      end

  This generates a story pointing at `SDUIRoot` with a render tree derived from
  the resolved view. For low-level component stories, you can still pass
  `resource:` to build a single mock node from `default_component`.

  ## Requirements

  - Prefer `ui:` and `view:` for generated view stories
  - Raw `resource:` stories require `default_component` or `:component_name`
  - `phoenix_storybook` must be available as a dependency
  """

  defmacro __using__(opts) do
    normalized_opts = normalize_macro_opts(opts, __CALLER__)

    quote do
      if Code.ensure_loaded?(PhoenixStorybook.Story) do
        use PhoenixStorybook.Story, :component
        alias PhoenixStorybook.Stories.Variation

        def function, do: &AshSDUI.Storybook.render/1

        def variations do
          [
            %Variation{
              id: :default,
              attributes: AshSDUI.Storybook.story_assigns(unquote(Macro.escape(normalized_opts)))
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

  def render(assigns) do
    AshSDUI.Components.SDUIRoot.render(assigns)
  end

  def story_assigns(opts) when is_list(opts) do
    cond do
      opts[:ui] ->
        view_assigns(opts)

      opts[:resource] ->
        %{tree: AshSDUI.Mock.from_resource(Keyword.fetch!(opts, :resource), opts)}

      true ->
        raise ArgumentError, "AshSDUI.Storybook expects :ui or :resource"
    end
  end

  defp view_assigns(opts) do
    ui = Keyword.fetch!(opts, :ui)
    view_name = Keyword.get(opts, :view, :index)
    params = Keyword.get(opts, :params, %{})
    context = Keyword.get(opts, :context, %{})
    recipe = Keyword.get(opts, :recipe)
    recipe_overrides = Keyword.get(opts, :recipe_overrides, %{})
    assigns = Keyword.get(opts, :assigns, %{})
    bindings = Keyword.get(opts, :bindings, %{})
    form = Keyword.get(opts, :form)

    view_opts =
      [
        params: params,
        context: context,
        recipe_overrides: recipe_overrides,
        assigns: assigns
      ]
      |> maybe_put(:recipe, recipe)

    {:ok, view} = AshSDUI.View.resolve(ui, view_name, view_opts)

    state =
      (view.state || %AshSDUI.View.State{})
      |> then(fn state ->
        %{state | assigns: Map.merge(state.assigns, %{bindings: bindings})}
      end)

    {:ok, tree} =
      AshSDUI.View.to_tree(view,
        bindings: bindings,
        form: form,
        state: state,
        context: view.context
      )

    %{tree: tree, context: view.context}
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp normalize_macro_opts(opts, env) do
    Enum.map(opts, fn
      {key, value} -> {key, normalize_macro_value(value, env)}
      other -> other
    end)
  end

  defp normalize_macro_value(value, env) do
    value
    |> Macro.expand(env)
    |> then(fn expanded ->
      try do
        case Code.eval_quoted(expanded, [], env) do
          {result, _binding} -> result
        end
      rescue
        _ -> expanded
      end
    end)
  end
end
