defmodule MaplibrexDemoWeb.Examples.VectorTileSourceExample do
  @moduledoc """
  The example of `<.vector_tile_source>`: MapLibre's public demo tiles of
  the world's countries, drawn by a fill and a line layer, added and removed
  with `:if`, with the source's events reporting its progress.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  # Values of the tiles' CONTINENT field.
  @continents ["Africa", "Asia", "Europe", "North America", "South America", "Oceania"]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(continent: "Europe", status: "waiting", data_events: 0, map_error: nil)
      |> assign_enabled(true)

    {:ok, socket}
  end

  # Driven from the server: the continent is part of the fill's paint, and
  # :if adds or removes the source together with its layers.

  @impl true
  def handle_event("continent", %{"continent" => slug}, socket) do
    case Enum.find(@continents, &(slug(&1) == slug)) do
      nil -> {:noreply, socket}
      continent -> {:noreply, assign(socket, :continent, continent)}
    end
  end

  def handle_event("options", %{"enabled" => enabled}, socket) do
    {:noreply, assign_enabled(socket, enabled == "true")}
  end

  # Events from the source. source:data arrives for every tile requested and
  # loaded; isSourceLoaded says whether every tile in view has arrived.

  def handle_event("source:added", _payload, socket) do
    {:noreply, assign(socket, :status, "added")}
  end

  def handle_event("source:data", %{"tile" => %{"isSourceLoaded" => loaded?}}, socket) do
    {:noreply,
     socket
     |> assign(:status, if(loaded?, do: "loaded", else: "loading"))
     |> update(:data_events, &(&1 + 1))}
  end

  def handle_event("source:removed", _payload, socket) do
    {:noreply, assign(socket, :status, "removed")}
  end

  def handle_event(event, %{"error" => message}, socket)
      when event in ["map:error", "source:error"] do
    {:noreply, assign(socket, :map_error, message)}
  end

  # source:data without a tile, the layers' events and the map's events
  # arrive too; this example does not use them.
  def handle_event("source:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("layer:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  # The chosen continent in the accent colour, the rest left unfilled.
  defp fill_paint(continent) do
    %{
      "fill-color" => ["case", ["==", ["get", "CONTINENT"], continent], "#5b3fa6", "#d8d8e0"],
      "fill-opacity" => ["case", ["==", ["get", "CONTINENT"], continent], 0.55, 0.15]
    }
  end

  defp assign_enabled(socket, enabled) do
    assign(socket, enabled: enabled, options: to_form(%{"enabled" => enabled}))
  end

  defp continents, do: @continents
  defp slug(continent), do: continent |> String.downcase() |> String.replace(" ", "_")

  defp continent_name("Africa"), do: gettext("Africa")
  defp continent_name("Asia"), do: gettext("Asia")
  defp continent_name("Europe"), do: gettext("Europe")
  defp continent_name("North America"), do: gettext("North America")
  defp continent_name("South America"), do: gettext("South America")
  defp continent_name("Oceania"), do: gettext("Oceania")
end
