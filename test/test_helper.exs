Application.ensure_all_started(:telemetry)
Logger.configure(level: :warning)

ExUnit.start()
