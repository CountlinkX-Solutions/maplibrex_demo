defmodule MaplibrexDemoWeb.Examples.RasterDemSourceExample do
  @moduledoc """
  The example of `<.raster_dem_source>`: elevation tiles from a public DEM
  service, made visible by a hillshade layer, with the source's events
  reporting its progress.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale,
  # copies each map event to the page's Events tab and keeps @theme on the
  # page's light or dark theme.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  # OpenFreeMap's basemap for the page's theme: the map's style follows @theme.
  defp basemap("dark"), do: "https://tiles.openfreemap.org/styles/dark"
  defp basemap("light"), do: "https://tiles.openfreemap.org/styles/positron"

  @places [
    %{id: "alps", center: [11.3909, 47.2757]},
    %{id: "andes", center: [-70.0109, -32.6532]},
    %{id: "himalaya", center: [86.925, 27.9881]}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       place: "alps",
       center: hd(@places).center,
       status: "waiting",
       data_events: 0,
       map_error: nil
     )}
  end

  @impl true
  def handle_event("go", %{"place" => id}, socket) do
    case Enum.find(@places, &(&1.id == id)) do
      nil -> {:noreply, socket}
      place -> {:noreply, assign(socket, place: place.id, center: place.center)}
    end
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

  def handle_event("source:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, status: "error", map_error: message)}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # source:data without a tile (the TileJSON arriving), the hillshade layer's
  # events and the map's events arrive too; this example does not use them.
  def handle_event("source:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("layer:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp places do
    names = %{
      "alps" => gettext("Alps"),
      "andes" => gettext("Andes"),
      "himalaya" => gettext("Himalaya")
    }

    Enum.map(@places, &{&1.id, names[&1.id]})
  end
end
