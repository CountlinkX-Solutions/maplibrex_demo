defmodule MaplibrexDemoWeb.NotFoundError do
  @moduledoc "Raised for a URL that names nothing in the catalogue; rendered as a 404."
  defexception message: "not found", plug_status: 404
end
