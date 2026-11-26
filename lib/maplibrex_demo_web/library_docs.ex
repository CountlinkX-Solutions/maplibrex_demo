defmodule MaplibrexDemoWeb.LibraryDocs do
  @moduledoc """
  What the demo reads from the MaplibreX library itself, at run time, so that
  it cannot drift from the version it runs against.
  """

  @doc "The version of the MaplibreX application the demo is running."
  @spec version() :: String.t()
  def version do
    case Application.spec(:maplibrex, :vsn) do
      nil -> "?"
      vsn -> List.to_string(vsn)
    end
  end
end
