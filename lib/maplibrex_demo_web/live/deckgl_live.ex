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
    <div class="relative w-full h-screen overflow-hidden bg-[#050810]">
      <%!-- Map full-screen --%>
      <.map
        id="deckgl-map"
        center={[-95, 40]}
        zoom={4}
        pitch={45}
        bearing={0}
        style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
        class="absolute inset-0 w-full h-full"
      />

      <%!-- Navigation Control --%>
      <.navigation_control
        id="nav-control"
        map_id="deckgl-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- Back nav --%>
      <div class="absolute top-[110px] left-4 z-20">
        <a href="/" class="flex items-center gap-2 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-4 py-2 text-sm text-white/70 hover:text-white transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] no-underline">
          &larr; Demos
        </a>
      </div>

      <%!-- Control Panel --%>
      <div class="absolute top-4 right-4 bottom-16 w-72 z-20 overflow-y-auto">
        <div class="bg-[rgba(8,12,28,0.85)] backdrop-blur-xl border border-white/[0.09] rounded-2xl p-5 space-y-5">
          <%!-- Header --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-1">MaplibreX</p>
            <h2 class="text-base font-semibold text-white/95">Deck.GL Layers</h2>
            <p class="text-xs text-white/50 mt-1 leading-relaxed">3D ArcLayer, HexagonLayer, and ScatterplotLayer visualizations</p>
          </div>
          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Visualization selector --%>
          <div class="space-y-2">
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">Visualization</p>
            <div class="space-y-1.5">
              <button
                phx-click="change_viz"
                phx-value-viz="arcs"
                class={if @current_viz == "arcs",
                  do: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                  else: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"}
              >
                <div class="font-medium">Flight Connections</div>
                <div class="text-[10px] opacity-60 mt-0.5">ArcLayer &mdash; {length(@flight_data)} routes</div>
              </button>
              <button
                phx-click="change_viz"
                phx-value-viz="hexagons"
                class={if @current_viz == "hexagons",
                  do: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                  else: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"}
              >
                <div class="font-medium">Earthquake Density</div>
                <div class="text-[10px] opacity-60 mt-0.5">HexagonLayer &mdash; {length(@earthquake_data)} events</div>
              </button>
              <button
                phx-click="change_viz"
                phx-value-viz="scatter"
                class={if @current_viz == "scatter",
                  do: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                  else: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"}
              >
                <div class="font-medium">City Points</div>
                <div class="text-[10px] opacity-60 mt-0.5">ScatterplotLayer &mdash; {length(@city_data)} cities</div>
              </button>
            </div>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Description for current visualization --%>
          <div class="space-y-1.5">
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">About</p>
            <%= if @current_viz == "arcs" do %>
              <p class="text-xs text-white/50 leading-relaxed">ArcLayer renders animated arcs connecting source and target positions. Ideal for visualizing flight routes, migrations, or connections between locations.</p>
            <% end %>
            <%= if @current_viz == "hexagons" do %>
              <p class="text-xs text-white/50 leading-relaxed">HexagonLayer aggregates points into hexagonal bins with 3D elevation. Perfect for showing density and spatial distribution patterns.</p>
            <% end %>
            <%= if @current_viz == "scatter" do %>
              <p class="text-xs text-white/50 leading-relaxed">ScatterplotLayer efficiently renders thousands of points with customizable size and color. Ideal for showing individual geographic locations.</p>
            <% end %>
          </div>
        </div>
      </div>

      <%!-- Telemetry bar --%>
      <div class="absolute bottom-4 left-4 z-20">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-xl px-4 py-3 flex items-center gap-4">
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">Layer</p>
            <p class="font-mono text-xs text-cyan-300/90">
              <%= case @current_viz do %>
                <% "arcs" -> %>ArcLayer
                <% "hexagons" -> %>HexagonLayer
                <% "scatter" -> %>ScatterplotLayer
                <% _ -> %>Unknown
              <% end %>
            </p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">Render</p>
            <p class="font-mono text-xs text-cyan-300/90">3D</p>
          </div>
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
