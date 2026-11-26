defmodule MaplibrexDemoWeb.Examples.HillshadeLayerExample do
  @moduledoc """
  The example of `<.hillshade_layer>`: relief shading from a raster DEM
  source, in one of three looks set by its paint, shown and hidden with
  `:if`.
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

  # Paint for each look; "plain" keeps MapLibre's defaults.
  @looks %{
    "plain" => %{},
    "strong" => %{
      "hillshade-exaggeration" => 1.0,
      "hillshade-illumination-direction" => 315
    },
    "warm" => %{
      "hillshade-exaggeration" => 0.7,
      "hillshade-shadow-color" => "#473b24",
      "hillshade-highlight-color" => "#fff8e7",
      "hillshade-accent-color" => "#8a7f71"
    }
  }

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(look: "plain", visible: true, on_map: false, map_error: nil)
      |> assign(:options, to_form(%{"visible" => true}))

    {:ok, socket}
  end

  @impl true
  def handle_event("look", %{"look" => look}, socket) when is_map_key(@looks, look) do
    {:noreply, assign(socket, :look, look)}
  end

  def handle_event("look", _params, socket), do: {:noreply, socket}

  def handle_event("options", %{"visible" => visible}, socket) do
    {:noreply,
     assign(socket, visible: visible == "true", options: to_form(%{"visible" => visible}))}
  end

  # Events from the layer: it is on the map from layer:added until
  # layer:removed. A new paint sends neither.

  def handle_event("layer:added", _payload, socket) do
    {:noreply, assign(socket, :on_map, true)}
  end

  def handle_event("layer:removed", _payload, socket) do
    {:noreply, assign(socket, :on_map, false)}
  end

  def handle_event(event, %{"error" => message}, socket)
      when event in ["map:error", "source:error"] do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The source's other events and the map's events arrive too; this example
  # does not use them.
  def handle_event("source:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp looks, do: Map.keys(@looks)
  defp paint(look), do: @looks[look]
end
