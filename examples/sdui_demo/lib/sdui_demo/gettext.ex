defmodule SduiDemo.Gettext do
  @moduledoc """
  Gettext backend for SduiDemo translations.

  SDUI labels use the "sdui" domain (priv/gettext/en/LC_MESSAGES/sdui.po).
  """
  use Gettext.Backend, otp_app: :sdui_demo
end
