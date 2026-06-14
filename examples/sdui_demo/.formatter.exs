[
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"],
  subdirectories: ["apps/*"],
  import_deps: [:ecto, :phoenix]
]
