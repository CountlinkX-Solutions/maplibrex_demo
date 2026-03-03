defmodule MaplibrexDemoWeb.HeatmapLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:radius, 25)
      |> assign(:intensity, 1.0)
      |> assign(:opacity, 0.8)
      |> assign(:earthquake_data, generate_earthquake_data())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative h-screen w-full">
      <%!-- Mapa base --%>
      <.map
        id="heatmap-map"
        center={[-98.5, 39.8]}
        zoom={3.5}
        pitch={0}
        bearing={0}
        style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
        class="absolute top-0 left-0 w-full h-full"
      />

      <%!-- Navigation Control --%>
      <.navigation_control
        id="nav-control"
        map_id="heatmap-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- Heatmap Layer usando GeoJSON --%>
      <.geojson_layer
        id="earthquake-heatmap"
        map_id="heatmap-map"
        data={@earthquake_data}
        type="heatmap"
        paint={%{
          "heatmap-weight" => [
            "interpolate",
            ["linear"],
            ["get", "magnitude"],
            0,
            0,
            6,
            1
          ],
          "heatmap-intensity" => [
            "interpolate",
            ["linear"],
            ["zoom"],
            0,
            @intensity,
            9,
            @intensity * 3
          ],
          "heatmap-color" => [
            "interpolate",
            ["linear"],
            ["heatmap-density"],
            0,
            "rgba(33,102,172,0)",
            0.2,
            "rgb(103,169,207)",
            0.4,
            "rgb(209,229,240)",
            0.6,
            "rgb(253,219,199)",
            0.8,
            "rgb(239,138,98)",
            1,
            "rgb(178,24,43)"
          ],
          "heatmap-radius" => [
            "interpolate",
            ["linear"],
            ["zoom"],
            0,
            @radius / 4,
            9,
            @radius
          ],
          "heatmap-opacity" => @opacity
        }}
      />

      <%!-- Panel de Control --%>
      <div class="absolute top-4 right-4 bg-white rounded-lg shadow-2xl p-6 max-w-sm z-10">
        <h2 class="text-2xl font-bold mb-4 border-b border-gray-300 pb-2">
          🔥 Earthquake Heatmap
        </h2>

        <%!-- Control de Radio --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Radius: <%= @radius %>px
          </label>
          <form phx-change="update_radius">
            <input
              type="range"
              min="10"
              max="50"
              step="5"
              value={@radius}
              name="value"
              class="w-full"
            />
          </form>
          <div class="flex justify-between text-xs text-gray-500 mt-1">
            <span>10px</span>
            <span>50px</span>
          </div>
        </div>

        <%!-- Control de Intensidad --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Intensity: <%= Float.round(@intensity, 2) %>x
          </label>
          <form phx-change="update_intensity">
            <input
              type="range"
              min="0.5"
              max="3.0"
              step="0.1"
              value={@intensity}
              name="value"
              class="w-full"
            />
          </form>
          <div class="flex justify-between text-xs text-gray-500 mt-1">
            <span>0.5x</span>
            <span>3.0x</span>
          </div>
        </div>

        <%!-- Control de Opacidad --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Opacity: <%= trunc(@opacity * 100) %>%
          </label>
          <form phx-change="update_opacity">
            <input
              type="range"
              min="0"
              max="1"
              step="0.1"
              value={@opacity}
              name="value"
              class="w-full"
            />
          </form>
          <div class="flex justify-between text-xs text-gray-500 mt-1">
            <span>0%</span>
            <span>100%</span>
          </div>
        </div>

        <%!-- Gradient Legend --%>
        <div class="mb-4 p-3 bg-gray-50 rounded">
          <p class="text-xs font-semibold text-gray-700 mb-2">Density Gradient:</p>
          <div class="h-4 rounded" style="background: linear-gradient(to right, rgba(33,102,172,0), rgb(103,169,207), rgb(209,229,240), rgb(253,219,199), rgb(239,138,98), rgb(178,24,43));"></div>
          <div class="flex justify-between text-xs text-gray-500 mt-1">
            <span>Low</span>
            <span>High</span>
          </div>
        </div>

        <%!-- Info --%>
        <div class="mt-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
          <h3 class="font-semibold mb-2 text-sm text-blue-900">About:</h3>
          <p class="text-xs text-blue-800">
            This demo shows earthquake density using a heatmap visualization.
            Adjust the controls to see how radius, intensity, and opacity affect the visualization.
          </p>
          <p class="text-xs text-blue-600 mt-2">
            Data: <%= length(@earthquake_data["features"]) %> earthquake events
          </p>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  @impl true
  def handle_event("update_radius", %{"value" => value}, socket) do
    radius =
      case Integer.parse(value) do
        {int_value, _} -> int_value
        :error -> 25
      end

    {:noreply, assign(socket, :radius, radius)}
  end

  @impl true
  def handle_event("update_intensity", %{"value" => value}, socket) do
    intensity =
      case Float.parse(value) do
        {float_value, _} -> float_value
        :error -> 1.0
      end

    {:noreply, assign(socket, :intensity, intensity)}
  end

  @impl true
  def handle_event("update_opacity", %{"value" => value}, socket) do
    opacity =
      case Float.parse(value) do
        {float_value, _} -> float_value
        :error -> 0.8
      end

    {:noreply, assign(socket, :opacity, opacity)}
  end

  @impl true
  def handle_event("map:loaded", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:moved", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:zoom_changed", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:clicked", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:error", %{"error" => error}, socket) do
    IO.inspect(error, label: "Map error")
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:added", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:removed", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:source_loaded", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:feature_clicked", %{"feature" => feature}, socket) do
    IO.inspect(feature, label: "Earthquake clicked")
    {:noreply, socket}
  end

  # Helper Functions

  defp generate_earthquake_data do
    # Generate 500 random earthquake points across USA
    features =
      for _ <- 1..500 do
        # Random coordinates within USA bounds
        lng = -125.0 + :rand.uniform() * 55.0
        lat = 25.0 + :rand.uniform() * 25.0
        magnitude = 2.0 + :rand.uniform() * 4.0

        %{
          "type" => "Feature",
          "geometry" => %{
            "type" => "Point",
            "coordinates" => [lng, lat]
          },
          "properties" => %{
            "magnitude" => magnitude,
            "depth" => :rand.uniform() * 100
          }
        }
      end

    %{
      "type" => "FeatureCollection",
      "features" => features
    }
  end
end
