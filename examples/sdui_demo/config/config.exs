import Config

config :sdui_demo, SduiDemoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SduiDemoWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: SduiDemo.PubSub,
  live_view: [signing_salt: "sdui_demo_salt"]

config :sdui_demo, :ash_domains, [SduiDemo.Accounts, SduiDemo.Blog]

config :tailwind,
  version_check: false,
  path: Path.expand("../assets/node_modules/.bin/tailwindcss", __DIR__)

import_config "#{config_env()}.exs"
