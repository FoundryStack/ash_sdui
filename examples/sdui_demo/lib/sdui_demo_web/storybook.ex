defmodule SduiDemoWeb.Storybook do
  use PhoenixStorybook,
    otp_app: :sdui_demo,
    css_path: "/assets/app.css",
    content_path: Path.expand("../../priv/storybook", __DIR__)
end
