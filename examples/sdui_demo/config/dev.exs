import Config

config :sdui_demo, SduiDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "sdui_demo_dev_secret_key_base_must_be_at_least_64_bytes_long_123456",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

config :esbuild,
  version: "0.21.4",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:./fonts/* --external:./images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.3",
  default: [
    args: ~w(--input=css/app.css --output=../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
