defmodule MaplibrexDemoWeb.DeckglLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_viz, "arcs")
      |> assign(:flight_data, generate_flight_data())
      |> assign(:earthquake_data, generate_earthquake_data())
      |> assign(:city_data, generate_city_data())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative h-screen w-full bg-gray-900">
      <%!-- Mapa con estilo oscuro --%>
      <.map
        id="deckgl-map"
        center={[-95, 40]}
        zoom={4}
        pitch={45}
        bearing={0}
        style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
        class="absolute top-0 left-0 w-full h-full"
      />

      <.navigation_control
        id="nav-control"
        map_id="deckgl-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- Panel de Control --%>
      <div class="absolute top-4 right-4 bg-gray-800 text-white rounded-lg shadow-2xl p-6 max-w-sm z-10">
        <h2 class="text-2xl font-bold mb-4 border-b border-gray-600 pb-2">
          🚀 deck.gl Visualizations
        </h2>

        <div class="mb-4">
          <p class="text-sm text-gray-400 mb-3">Select visualization:</p>
          <div class="space-y-2">
            <button
              phx-click="change_viz"
              phx-value-viz="arcs"
              class={[
                "w-full text-left px-4 py-3 rounded-lg transition-all",
                if(@current_viz == "arcs",
                  do: "bg-blue-600 text-white shadow-lg",
                  else: "bg-gray-700 text-gray-300 hover:bg-gray-600"
                )
              ]}
            >
              <div class="font-semibold">✈️ Flight Connections</div>
              <div class="text-xs opacity-75">ArcLayer - <%= length(@flight_data) %> routes</div>
            </button>

            <button
              phx-click="change_viz"
              phx-value-viz="hexagons"
              class={[
                "w-full text-left px-4 py-3 rounded-lg transition-all",
                if(@current_viz == "hexagons",
                  do: "bg-blue-600 text-white shadow-lg",
                  else: "bg-gray-700 text-gray-300 hover:bg-gray-600"
                )
              ]}
            >
              <div class="font-semibold">🌍 Earthquake Density</div>
              <div class="text-xs opacity-75">
                HexagonLayer - <%= length(@earthquake_data) %> events
              </div>
            </button>

            <button
              phx-click="change_viz"
              phx-value-viz="scatter"
              class={[
                "w-full text-left px-4 py-3 rounded-lg transition-all",
                if(@current_viz == "scatter",
                  do: "bg-blue-600 text-white shadow-lg",
                  else: "bg-gray-700 text-gray-300 hover:bg-gray-600"
                )
              ]}
            >
              <div class="font-semibold">🏙️ City Points</div>
              <div class="text-xs opacity-75">
                ScatterplotLayer - <%= length(@city_data) %> cities
              </div>
            </button>
          </div>
        </div>

        <%!-- Descripción de la visualización actual --%>
        <div class="mt-6 p-4 bg-gray-900 rounded-lg border border-gray-700">
          <h3 class="font-semibold mb-2 text-sm text-gray-300">About this visualization:</h3>
          <p class="text-xs text-gray-400">
            <%= case @current_viz do %>
              <% "arcs" -> %>
                ArcLayer renders animated arcs connecting source and target positions. Great for visualizing flights, migrations, or connections between locations.
              <% "hexagons" -> %>
                HexagonLayer aggregates points into hexagonal bins with 3D elevation. Perfect for showing density and distribution patterns.
              <% "scatter" -> %>
                ScatterplotLayer efficiently renders thousands of points with customizable size and color. Ideal for showing individual locations.
            <% end %>
          </p>
        </div>

        <div class="mt-4 pt-4 border-t border-gray-700 text-xs text-gray-500">
          Powered by deck.gl + MapLibre GL JS
        </div>
      </div>

      <%!-- DeckGL Layers --%>
      <%= if @current_viz == "arcs" do %>
        <.deckgl_layer
          id="flight-arcs"
          map_id="deckgl-map"
          layer_type="ArcLayer"
          data={@flight_data}
          pickable={true}
          props={%{
            "getSourcePosition" => "from",
            "getTargetPosition" => "to",
            "getSourceColor" => [255, 140, 0],
            "getTargetColor" => [255, 200, 0],
            "getWidth" => 2
          }}
        />
      <% end %>

      <%= if @current_viz == "hexagons" do %>
        <.deckgl_layer
          id="earthquake-hexagons"
          map_id="deckgl-map"
          layer_type="HexagonLayer"
          data={@earthquake_data}
          auto_highlight={true}
          props={%{
            "getPosition" => "coordinates",
            "elevationScale" => 50,
            "radius" => 50000,
            "coverage" => 0.9,
            "extruded" => true,
            "colorRange" => [
              [1, 152, 189],
              [73, 227, 206],
              [216, 254, 181],
              [254, 237, 177],
              [254, 173, 84],
              [209, 55, 78]
            ]
          }}
        />
      <% end %>

      <%= if @current_viz == "scatter" do %>
        <.deckgl_layer
          id="city-scatter"
          map_id="deckgl-map"
          layer_type="ScatterplotLayer"
          data={@city_data}
          pickable={true}
          props={%{
            "getPosition" => "coordinates",
            "getRadius" => 10000,
            "getFillColor" => [255, 140, 0],
            "radiusScale" => 6,
            "radiusMinPixels" => 2,
            "radiusMaxPixels" => 30
          }}
        />
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("change_viz", %{"viz" => viz}, socket) do
    {:noreply, assign(socket, :current_viz, viz)}
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
  def handle_event("map:error", %{"error" => error}, socket) do
    IO.inspect(error, label: "Map error")
    {:noreply, socket}
  end

  @impl true
  def handle_event("deckgl:layer_loaded", %{"layerId" => layer_id}, socket) do
    IO.inspect(layer_id, label: "DeckGL layer loaded")
    {:noreply, socket}
  end

  @impl true
  def handle_event("deckgl:click", %{"object" => object}, socket) do
    IO.inspect(object, label: "DeckGL object clicked")
    {:noreply, socket}
  end

  @impl true
  def handle_event("deckgl:hover", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("deckgl:error", %{"error" => error}, socket) do
    IO.inspect(error, label: "DeckGL error")
    {:noreply, socket}
  end

  @impl true
  def handle_event("deckgl:drag_start", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("deckgl:drag", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("deckgl:drag_end", _params, socket) do
    {:noreply, socket}
  end

  # Datos de ejemplo

  defp generate_flight_data do
    # Principales ciudades de USA
    cities = [
      {"New York", [-74.0, 40.7]},
      {"Los Angeles", [-118.2, 34.0]},
      {"Chicago", [-87.6, 41.9]},
      {"Houston", [-95.4, 29.8]},
      {"Phoenix", [-112.1, 33.4]},
      {"Philadelphia", [-75.2, 39.9]},
      {"San Antonio", [-98.5, 29.4]},
      {"San Diego", [-117.2, 32.7]},
      {"Dallas", [-96.8, 32.8]},
      {"San Jose", [-121.9, 37.3]},
      {"Austin", [-97.7, 30.3]},
      {"Jacksonville", [-81.7, 30.3]},
      {"San Francisco", [-122.4, 37.8]},
      {"Columbus", [-83.0, 40.0]},
      {"Indianapolis", [-86.2, 39.8]},
      {"Seattle", [-122.3, 47.6]},
      {"Denver", [-104.9, 39.7]},
      {"Boston", [-71.1, 42.4]},
      {"Portland", [-122.7, 45.5]},
      {"Las Vegas", [-115.1, 36.2]}
    ]

    # Generar conexiones entre ciudades (formato simple para deck.gl)
    for {from_name, from_coords} <- cities,
        {to_name, to_coords} <- cities,
        from_name != to_name,
        :rand.uniform() > 0.7 do
      %{
        "from" => from_coords,
        "to" => to_coords,
        "from_city" => from_name,
        "to_city" => to_name
      }
    end
  end

  defp generate_earthquake_data do
    # Generar terremotos aleatorios en zona sísmica de California
    for _ <- 1..800 do
      lng = -125.0 + :rand.uniform() * 15
      lat = 32.0 + :rand.uniform() * 10
      magnitude = 2.0 + :rand.uniform() * 5

      %{
        "coordinates" => [lng, lat],
        "magnitude" => magnitude
      }
    end
  end

  defp generate_city_data do
    # Generar ciudades aleatorias en USA
    for _ <- 1..500 do
      lng = -125.0 + :rand.uniform() * 55
      lat = 25.0 + :rand.uniform() * 25
      population = 10000 + :rand.uniform(1000000)

      %{
        "coordinates" => [lng, lat],
        "population" => population
      }
    end
  end
end
