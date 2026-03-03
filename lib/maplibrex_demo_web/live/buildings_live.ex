defmodule MaplibrexDemoWeb.BuildingsLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:height_exaggeration, 1.0)
      |> assign(:opacity, 0.8)
      |> assign(:color_scheme, "height")
      |> assign(:buildings_data, generate_buildings_data())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative h-screen w-full">
      <%!-- Mapa base --%>
      <.map
        id="buildings-map"
        center={[-74.006, 40.7128]}
        zoom={14}
        pitch={60}
        bearing={-17.6}
        style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
        class="absolute top-0 left-0 w-full h-full"
      />

      <%!-- Navigation Control --%>
      <.navigation_control
        id="nav-control"
        map_id="buildings-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- 3D Buildings Layer --%>
      <.geojson_layer
        id="buildings-3d"
        map_id="buildings-map"
        data={@buildings_data}
        type="fill-extrusion"
        paint={get_paint_properties(assigns)}
      />

      <%!-- Panel de Control --%>
      <div class="absolute top-4 right-4 bg-white rounded-lg shadow-2xl p-6 max-w-sm z-10">
        <h2 class="text-2xl font-bold mb-4 border-b border-gray-300 pb-2">
          🏢 3D Buildings
        </h2>

        <%!-- Control de Exageración de Altura --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Height Exaggeration: <%= Float.round(@height_exaggeration, 1) %>x
          </label>
          <form phx-change="update_height">
            <input
              type="range"
              min="0.5"
              max="3.0"
              step="0.1"
              value={@height_exaggeration}
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
              min="0.3"
              max="1"
              step="0.1"
              value={@opacity}
              name="value"
              class="w-full"
            />
          </form>
          <div class="flex justify-between text-xs text-gray-500 mt-1">
            <span>30%</span>
            <span>100%</span>
          </div>
        </div>

        <%!-- Selector de Esquema de Color --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Color Scheme:
          </label>
          <div class="space-y-2">
            <button
              phx-click="set_color_scheme"
              phx-value-scheme="height"
              class={[
                "w-full px-4 py-2 rounded-lg text-sm font-medium transition-all",
                if(@color_scheme == "height",
                  do: "bg-blue-500 text-white",
                  else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                )
              ]}
            >
              By Height (Gradient)
            </button>
            <button
              phx-click="set_color_scheme"
              phx-value-scheme="uniform"
              class={[
                "w-full px-4 py-2 rounded-lg text-sm font-medium transition-all",
                if(@color_scheme == "uniform",
                  do: "bg-blue-500 text-white",
                  else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                )
              ]}
            >
              Uniform Blue
            </button>
            <button
              phx-click="set_color_scheme"
              phx-value-scheme="type"
              class={[
                "w-full px-4 py-2 rounded-lg text-sm font-medium transition-all",
                if(@color_scheme == "type",
                  do: "bg-blue-500 text-white",
                  else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                )
              ]}
            >
              By Type
            </button>
          </div>
        </div>

        <%!-- Color Legend --%>
        <%= if @color_scheme == "height" do %>
          <div class="mb-4 p-3 bg-gray-50 rounded">
            <p class="text-xs font-semibold text-gray-700 mb-2">Height Legend:</p>
            <div class="h-4 rounded" style="background: linear-gradient(to right, #fbb03b, #223b53, #e55e5e);"></div>
            <div class="flex justify-between text-xs text-gray-500 mt-1">
              <span>Low</span>
              <span>High</span>
            </div>
          </div>
        <% end %>

        <%!-- Info --%>
        <div class="mt-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
          <h3 class="font-semibold mb-2 text-sm text-blue-900">About:</h3>
          <p class="text-xs text-blue-800">
            This demo shows 3D extruded buildings. Rotate the camera with right-click drag
            and adjust controls to see different visualizations.
          </p>
          <p class="text-xs text-blue-600 mt-2">
            Buildings: <%= length(@buildings_data["features"]) %> structures
          </p>
        </div>
      </div>
    </div>
    """
  end

  # Helper function to get paint properties based on color scheme
  defp get_paint_properties(assigns) do
    color_expression =
      case assigns.color_scheme do
        "height" ->
          [
            "interpolate",
            ["linear"],
            ["get", "height"],
            0,
            "#fbb03b",
            50,
            "#223b53",
            150,
            "#e55e5e"
          ]

        "uniform" ->
          "#4a90e2"

        "type" ->
          [
            "match",
            ["get", "type"],
            "residential",
            "#fbb03b",
            "commercial",
            "#223b53",
            "office",
            "#e55e5e",
            "#888888"
          ]

        _ ->
          "#4a90e2"
      end

    %{
      "fill-extrusion-color" => color_expression,
      "fill-extrusion-height" => ["*", ["get", "height"], assigns.height_exaggeration],
      "fill-extrusion-base" => ["get", "base_height"],
      "fill-extrusion-opacity" => assigns.opacity,
      "fill-extrusion-vertical-gradient" => true
    }
  end

  # Event Handlers

  @impl true
  def handle_event("update_height", %{"value" => value}, socket) do
    height =
      case Float.parse(value) do
        {float_value, _} -> float_value
        :error -> 1.0
      end

    {:noreply, assign(socket, :height_exaggeration, height)}
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
  def handle_event("set_color_scheme", %{"scheme" => scheme}, socket) do
    {:noreply, assign(socket, :color_scheme, scheme)}
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

  # Helper Functions

  defp generate_buildings_data do
    # Generate buildings in a grid pattern (simulating Manhattan)
    # Center: -74.006, 40.7128 (NYC)
    center_lng = -74.006
    center_lat = 40.7128

    building_types = ["residential", "commercial", "office"]

    features =
      for x <- 0..14, y <- 0..14 do
        # Create a small rectangular building
        lng_offset = (x - 7) * 0.002
        lat_offset = (y - 7) * 0.002

        lng = center_lng + lng_offset
        lat = center_lat + lat_offset

        # Building dimensions
        width = 0.0008 + :rand.uniform() * 0.0004
        depth = 0.0008 + :rand.uniform() * 0.0004

        # Building properties
        height = 20 + :rand.uniform() * 130
        base_height = :rand.uniform() < 0.1 && 5 || 0
        building_type = Enum.random(building_types)

        # Create polygon coordinates
        coordinates = [
          [
            [lng - width / 2, lat - depth / 2],
            [lng + width / 2, lat - depth / 2],
            [lng + width / 2, lat + depth / 2],
            [lng - width / 2, lat + depth / 2],
            [lng - width / 2, lat - depth / 2]
          ]
        ]

        %{
          "type" => "Feature",
          "geometry" => %{
            "type" => "Polygon",
            "coordinates" => coordinates
          },
          "properties" => %{
            "height" => height,
            "base_height" => base_height,
            "type" => building_type
          }
        }
      end

    %{
      "type" => "FeatureCollection",
      "features" => features
    }
  end
end
