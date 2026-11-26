defmodule MaplibrexDemoWeb.Examples.RasterTileSourceExample do
  @moduledoc """
  The example of `<.raster_tile_source>`: NASA's public imagery tiles as
  the whole map, on a style with no layers of its own. New tile URLs from
  the server are applied to the source in place.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  # NASA GIBS layers in Web Mercator, 256-pixel JPEG tiles up to zoom 8.
  # GIBS orders the tile path {z}/{y}/{x}.
  @imagery %{
    "day" => "BlueMarble_ShadedRelief_Bathymetry",
    "night" => "VIIRS_CityLights_2012"
  }

  # A style with no sources or layers: the raster layer is the whole map.
  @blank_style %{"version" => 8, "sources" => %{}, "layers" => []}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, imagery: "day", status: "waiting", data_events: 0, map_error: nil)}
  end

  # A new imagery is new tile URLs, which MaplibreX hands to the source
  # without removing it.
  @impl true
  def handle_event("imagery", %{"imagery" => imagery}, socket)
      when is_map_key(@imagery, imagery) do
    {:noreply, assign(socket, :imagery, imagery)}
  end

  def handle_event("imagery", _params, socket), do: {:noreply, socket}

  # Events from the source.

  def handle_event("source:added", _payload, socket) do
    {:noreply, assign(socket, :status, "added")}
  end

  def handle_event("source:data", %{"tile" => %{"isSourceLoaded" => loaded?}}, socket) do
    {:noreply,
     socket
     |> assign(:status, if(loaded?, do: "loaded", else: "loading"))
     |> update(:data_events, &(&1 + 1))}
  end

  def handle_event(event, %{"error" => message}, socket)
      when event in ["map:error", "source:error"] do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The source's other events, the layer's and the map's arrive too; this
  # example does not use them.
  def handle_event("source:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("layer:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp tiles(imagery) do
    [
      "https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/#{@imagery[imagery]}/default/GoogleMapsCompatible_Level8/{z}/{y}/{x}.jpeg"
    ]
  end

  defp imageries, do: ["day", "night"]
  defp blank_style, do: @blank_style

  defp imagery_name("day"), do: gettext("Blue Marble")
  defp imagery_name("night"), do: gettext("City lights, 2012")
end
