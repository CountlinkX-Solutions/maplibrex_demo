defmodule MaplibrexDemoWeb.Examples.GeojsonLayerExample do
  @moduledoc """
  The example of `<.geojson_layer>`: GeoJSON points drawn as a circle layer
  whose paint follows assigns, shown and hidden with `:if`, with the clicked
  point coming back as `layer:feature_clicked`.
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
  defp basemap("light"), do: "https://tiles.openfreemap.org/styles/liberty"

  @madrid [-3.7038, 40.4168]

  # Sample data: twelve points on a ring around Madrid, made up for this
  # example. Each feature carries the name shown when it is clicked.
  @points %{
    "type" => "FeatureCollection",
    "features" =>
      for i <- 1..12 do
        angle = i * :math.pi() / 6
        [lng, lat] = @madrid

        %{
          "type" => "Feature",
          "geometry" => %{
            "type" => "Point",
            "coordinates" => [lng + 0.06 * :math.cos(angle), lat + 0.045 * :math.sin(angle)]
          },
          "properties" => %{"name" => "Point #{i}"}
        }
      end
  }

  @colors [
    {"purple", "#7c5cd6"},
    {"teal", "#0f8b8d"},
    {"orange", "#d9480f"},
    {"red", "#c92a2a"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(center: @madrid, points: @points, selected: nil, map_error: nil)
      |> assign(color: "#7c5cd6", radius: 8, visible: true)
      |> assign_options()

    {:ok, socket}
  end

  # Driven from the server: paint is an assign, so a new value repaints the
  # layer, and :if adds or removes it.

  @impl true
  def handle_event("color", %{"color" => color}, socket) do
    if Enum.any?(@colors, fn {_name, hex} -> hex == color end) do
      {:noreply, assign(socket, :color, color)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("options", %{"radius" => radius, "visible" => visible}, socket) do
    {:noreply,
     socket
     |> assign(radius: integer(radius, socket.assigns.radius), visible: visible == "true")
     |> assign_options()}
  end

  # Events from the layer: a click on a point carries its feature.

  def handle_event("layer:feature_clicked", %{"feature" => feature}, socket) do
    {:noreply, assign(socket, :selected, feature["properties"]["name"])}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # layer:feature_mouseenter, layer:feature_mouseleave, layer:source_loaded
  # and the map's events arrive too; this example does not use them.
  def handle_event("layer:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp paint(color, radius) do
    %{
      "circle-color" => color,
      "circle-radius" => radius,
      "circle-stroke-color" => "#ffffff",
      "circle-stroke-width" => 2
    }
  end

  defp assign_options(socket) do
    %{radius: radius, visible: visible} = socket.assigns
    assign(socket, :options, to_form(%{"radius" => radius, "visible" => visible}))
  end

  defp colors, do: @colors

  # Slider values arrive as strings: "14".
  defp integer(value, fallback) do
    case Integer.parse(value) do
      {integer, _rest} -> integer
      :error -> fallback
    end
  end
end
