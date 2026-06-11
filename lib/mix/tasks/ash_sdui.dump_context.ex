defmodule Mix.Tasks.AshSdui.DumpContext do
  @moduledoc """
  Dumps the SDUI context (components, layouts, resources) to stdout.

  ## Usage

      mix ash_sdui.dump_context
      mix ash_sdui.dump_context --format json
      mix ash_sdui.dump_context --output context.md

  ## Options

  - `--format` - Output format: `markdown` (default) or `json`
  - `--output` - Write to file instead of stdout
  """

  use Mix.Task

  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: [format: :string, output: :string])
    format = String.to_atom(opts[:format] || "markdown")

    {:ok, content} = AshSDUI.ContextDumper.dump(format)

    case opts[:output] do
      nil -> IO.write(content)
      path -> File.write!(path, content)
    end
  end
end
