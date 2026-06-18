defmodule AshSDUI.LiveResource.QueryPatch do
  @moduledoc false

  import Phoenix.LiveView

  alias AshSDUI.Query

  def patch_query(socket, nil), do: socket

  def patch_query(socket, %Query{} = query) do
    path =
      socket.assigns[:ash_sdui_uri]
      |> current_path()
      |> Query.merge_path(query)

    push_patch(socket, to: path)
  end

  defp current_path(nil), do: "/"

  defp current_path(uri) do
    parsed = URI.parse(uri)
    parsed.path || "/"
  end
end
