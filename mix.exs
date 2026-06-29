defmodule AshSdui.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_sdui,
      name: "ash_sdui",
      source_url: "https://github.com/FoundryStack/ash_sdui",
      homepage_url: "https://hexdocs.pm/ash_sdui",
      version: "0.3.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  defp description() do
    "Server-Driven UI for Phoenix LiveView applications backed by Ash resources."
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/FoundryStack/ash_sdui"
      }
    ]
  end

  def application do
    [
      mod: {AshSDUI.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ash, "~> 3.20"},
      {:ash_paper_trail, "~> 0.5"},
      {:spark, "~> 2.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:phoenix_storybook, "~> 1.2", only: :dev, optional: true},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "docs/tutorials/build_your_first_generated_screen.md",
        "docs/how-to/author_generated_screens.md",
        "docs/how-to/customize_generated_forms.md",
        "docs/how-to/use_queries_and_filters.md",
        "docs/how-to/add_live_bindings.md",
        "docs/how-to/render_generated_views_in_storybook.md",
        "docs/how-to/use_layout_sdui_recipes.md",
        "docs/how-to/build_nested_layouts.md",
        "docs/how-to/work_with_sdui_layouts.md",
        "docs/reference/public_api.md",
        "docs/reference/runtime_contract.md",
        "docs/explanation/runtime_model.md",
        "docs/explanation/authoring_model.md",
        "docs/explanation/when_to_use_ash_sdui.md",
        "docs/explanation/demo_and_storybook.md"
      ],
      groups_for_extras: [
        Tutorials: ["docs/tutorials/*.md"],
        "How-to Guides": ["docs/how-to/*.md"],
        Reference: ["docs/reference/*.md"],
        Explanation: ["docs/explanation/*.md"]
      ]
    ]
  end
end
