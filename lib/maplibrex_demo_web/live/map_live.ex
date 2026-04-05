defmodule MaplibrexDemoWeb.MapLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:center, [-74.5, 40])
      |> assign(:zoom, 9)
      |> assign(:current_center, [-74.5, 40])
      |> assign(:current_zoom, 9)
      |> assign(:current_style, "https://demotiles.maplibre.org/style.json")
      |> assign(:markers, [
        %{id: "marker-1", lng_lat: [-74.5, 40], color: "red", draggable: false},
        %{id: "marker-2", lng_lat: [-74.0, 40.5], color: "blue", draggable: true},
        %{id: "marker-3", lng_lat: [-73.5, 40.2], color: "green", draggable: false}
      ])
      |> assign(:map_styles, [
        %{name: "OpenStreetMap", url: "https://demotiles.maplibre.org/style.json"},
        %{name: "Dark", url: "https://tiles.openfreemap.org/styles/dark"},
        %{name: "Liberty", url: "https://tiles.openfreemap.org/styles/liberty"}
      ])
      |> assign(:show_popups, true)
      |> assign(:show_geojson, true)
      |> assign(:demo_geojson, %{
        type: "FeatureCollection",
        features: [
          %{
            type: "Feature",
            properties: %{name: "NYC Area", description: "Demo GeoJSON Layer"},
            geometry: %{
              type: "Polygon",
              coordinates: [
                [
                  [-74.25, 40.9],
                  [-73.7, 40.9],
                  [-73.7, 40.5],
                  [-74.25, 40.5],
                  [-74.25, 40.9]
                ]
              ]
            }
          }
        ]
      })

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-full h-screen overflow-hidden bg-[#050810]">
      <%!-- Map fills full screen --%>
      <.map
        id="demo-map"
        center={@center}
        zoom={@zoom}
        style="https://demotiles.maplibre.org/style.json"
        class="absolute inset-0 w-full h-full"
      />

      <%!-- Map controls --%>
      <.navigation_control
        id="nav-control"
        map_id="demo-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
        visualize_pitch={false}
      />

      <.scale_control
        id="scale-control"
        map_id="demo-map"
        position="bottom-left"
        max_width={150}
        unit="metric"
      />

      <.fullscreen_control
        id="fullscreen-control"
        map_id="demo-map"
        position="top-left"
      />

      <%!-- GeoJSON Layer --%>
      <%= if @show_geojson do %>
        <.geojson_layer
          id="nyc-area"
          map_id="demo-map"
          data={@demo_geojson}
          type="fill"
          paint={%{
            "fill-color" => "#088",
            "fill-opacity" => 0.3,
            "fill-outline-color" => "#000"
          }}
        />
      <% end %>

      <%!-- Markers --%>
      <%= for marker <- @markers do %>
        <.marker
          id={marker.id}
          map_id="demo-map"
          lng_lat={marker.lng_lat}
          color={marker.color}
          draggable={marker.draggable}
          popup_text={if @show_popups, do: "Marker #{marker.id} - #{marker.color}", else: nil}
        />
      <% end %>

      <%!-- Back navigation pill --%>
      <div class="absolute top-4 left-4 z-20">
        <a
          href="/"
          class="flex items-center gap-2 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-4 py-2 text-sm text-white/75 hover:text-white transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"
        >
          ← MaplibreX Demos
        </a>
      </div>

      <%!-- Control Panel --%>
      <div class="absolute top-4 right-4 bottom-16 w-72 z-20 overflow-y-auto">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-2xl p-5 space-y-5">
          <%!-- Title --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-1">
              MaplibreX
            </p>
            <h2 class="text-base font-semibold text-white">Interactive Map</h2>
            <p class="text-xs text-white/50 mt-1">
              Markers, GeoJSON layers, real-time events
            </p>
          </div>

          <div class="border-t border-white/[0.06]" />

          <%!-- Map Style --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              Map Style
            </p>
            <div class="space-y-1">
              <%= for style <- @map_styles do %>
                <button
                  onclick={"document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:set_style', {detail: {style: '#{style.url}'}}))"}
                  phx-click="update_style"
                  phx-value-url={style.url}
                  class={
                    if @current_style == style.url,
                      do: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                      else: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/70 hover:text-white hover:bg-white/[0.07] border border-transparent hover:border-white/[0.08] transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"
                  }
                >
                  {style.name}
                </button>
              <% end %>
            </div>
          </div>

          <div class="border-t border-white/[0.06]" />

          <%!-- Navigation --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              Navigation
            </p>
            <div class="flex gap-2">
              <button
                onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [-73.98, 40.75], zoom: 12, duration: 1000}}))"
                class="flex-1 px-3 py-2 rounded-lg text-xs text-white/70 bg-white/[0.05] hover:bg-white/[0.10] border border-white/[0.07] transition-all duration-300 text-center"
              >
                NYC
              </button>
              <button
                onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [-118.24, 34.05], zoom: 12, duration: 1500}}))"
                class="flex-1 px-3 py-2 rounded-lg text-xs text-white/70 bg-white/[0.05] hover:bg-white/[0.10] border border-white/[0.07] transition-all duration-300 text-center"
              >
                Los Angeles
              </button>
              <button
                onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [-74.5, 40], zoom: 9, duration: 1500}}))"
                class="flex-1 px-3 py-2 rounded-lg text-xs text-white/70 bg-white/[0.05] hover:bg-white/[0.10] border border-white/[0.07] transition-all duration-300 text-center"
              >
                Reset
              </button>
            </div>
          </div>

          <div class="border-t border-white/[0.06]" />

          <%!-- Layers --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              Layers
            </p>
            <button
              phx-click="toggle_geojson"
              class={
                if @show_geojson,
                  do: "w-full text-left px-3 py-2.5 rounded-lg text-sm bg-cyan-500/10 border border-cyan-400/25 text-cyan-300 transition-all duration-300",
                  else: "w-full text-left px-3 py-2.5 rounded-lg text-sm bg-white/[0.05] border border-white/[0.07] text-white/60 transition-all duration-300"
              }
            >
              <span class="font-medium">GeoJSON Layer</span>
              <span class="ml-2 text-xs opacity-70">
                {if @show_geojson, do: "Visible", else: "Hidden"}
              </span>
            </button>
          </div>

          <div class="border-t border-white/[0.06]" />

          <%!-- Markers --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              Markers
            </p>
            <div class="flex gap-2">
              <button
                phx-click="add_marker"
                class="flex-1 px-3 py-2 rounded-lg text-xs text-white/70 bg-white/[0.05] hover:bg-white/[0.10] border border-white/[0.07] transition-all duration-300 text-center"
              >
                Add Marker
              </button>
              <button
                phx-click="clear_markers"
                class="flex-1 px-3 py-2 rounded-lg text-xs text-white/70 bg-white/[0.05] hover:bg-white/[0.10] border border-white/[0.07] transition-all duration-300 text-center"
              >
                Clear All
              </button>
            </div>
          </div>
        </div>
      </div>

      <%!-- Telemetry panel --%>
      <div class="absolute bottom-4 left-4 z-20">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-xl px-4 py-3 flex items-center gap-4">
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">Center</p>
            <p class="font-mono text-xs text-cyan-300">
              {Float.round(Enum.at(@current_center, 0) * 1.0, 3)},
              {Float.round(Enum.at(@current_center, 1) * 1.0, 3)}
            </p>
          </div>
          <div class="w-px h-6 bg-white/10" />
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">Zoom</p>
            <p class="font-mono text-xs text-cyan-300">
              {Float.round(@current_zoom * 1.0, 1)}
            </p>
          </div>
          <div class="w-px h-6 bg-white/10" />
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">Markers</p>
            <p class="font-mono text-xs text-cyan-300">{length(@markers)}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("update_style", %{"url" => url}, socket) do
    {:noreply, assign(socket, :current_style, url)}
  end

  @impl true
  def handle_event("add_marker", _params, socket) do
    # Generar posición aleatoria cerca del centro actual
    [lng, lat] = socket.assigns.center
    new_lng = lng + (:rand.uniform() - 0.5) * 2
    new_lat = lat + (:rand.uniform() - 0.5) * 2

    colors = ["red", "blue", "green", "purple", "orange", "yellow", "pink"]
    random_color = Enum.random(colors)

    new_marker = %{
      id: "marker-#{System.unique_integer([:positive])}",
      lng_lat: [new_lng, new_lat],
      color: random_color,
      draggable: true
    }

    socket =
      socket
      |> assign(:markers, socket.assigns.markers ++ [new_marker])
      |> push_event("fly_to_marker", %{lng: new_lng, lat: new_lat})

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_markers", _params, socket) do
    {:noreply, assign(socket, :markers, [])}
  end

  @impl true
  def handle_event("toggle_geojson", _params, socket) do
    {:noreply, assign(socket, :show_geojson, !socket.assigns.show_geojson)}
  end

  @impl true
  def handle_event("toggle_popups", _params, socket) do
    {:noreply, assign(socket, :show_popups, !socket.assigns.show_popups)}
  end

  @impl true
  def handle_event("map:loaded", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:fly_to", _params, socket) do
    # El comando JS ya se ejecutó en el cliente, solo ignoramos el evento del servidor
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:zoom_in", _params, socket) do
    # El comando JS ya se ejecutó en el cliente, solo ignoramos el evento del servidor
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:zoom_out", _params, socket) do
    # El comando JS ya se ejecutó en el cliente, solo ignoramos el evento del servidor
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:reset_north", _params, socket) do
    # El comando JS ya se ejecutó en el cliente, solo ignoramos el evento del servidor
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:zoom_changed", %{"zoom" => zoom}, socket) do
    # Actualizar el zoom mostrado en el estado (sin re-renderizar el mapa)
    {:noreply, assign(socket, :current_zoom, zoom)}
  end

  @impl true
  def handle_event("map:moved", %{"center" => center, "zoom" => zoom}, socket) do
    # Actualizar centro y zoom mostrados en el estado (sin re-renderizar el mapa)
    socket =
      socket
      |> assign(:current_center, center)
      |> assign(:current_zoom, zoom)

    {:noreply, socket}
  end

  @impl true
  def handle_event("map:clicked", %{"lngLat" => lng_lat}, socket) do
    IO.inspect(lng_lat, label: "Map clicked at")
    {:noreply, socket}
  end

  @impl true
  def handle_event("marker:clicked", %{"markerId" => marker_id, "lngLat" => lng_lat}, socket) do
    IO.inspect({marker_id, lng_lat}, label: "Marker clicked")
    {:noreply, socket}
  end

  @impl true
  def handle_event("marker:drag_start", %{"markerId" => marker_id, "lngLat" => lng_lat}, socket) do
    # Evento cuando se comienza a arrastrar un marcador
    IO.inspect({marker_id, lng_lat}, label: "Marker drag started")
    {:noreply, socket}
  end

  @impl true
  def handle_event("marker:dragging", %{"markerId" => marker_id, "lngLat" => lng_lat}, socket) do
    # Evento continuo mientras se arrastra el marcador
    # NO actualizamos el estado aquí para evitar re-renders constantes
    IO.inspect({marker_id, lng_lat}, label: "Marker dragging")
    {:noreply, socket}
  end

  @impl true
  def handle_event("marker:drag_end", %{"markerId" => marker_id, "lngLat" => lng_lat}, socket) do
    IO.inspect({marker_id, lng_lat}, label: "Marker dragged to")

    # Actualizar posición del marcador arrastrado
    markers =
      Enum.map(socket.assigns.markers, fn marker ->
        if marker.id == marker_id do
          %{marker | lng_lat: lng_lat}
        else
          marker
        end
      end)

    {:noreply, assign(socket, :markers, markers)}
  end

  @impl true
  def handle_event("layer:feature_mouseenter", %{"layerId" => layer_id, "feature" => feature}, socket) do
    # Evento cuando el mouse entra sobre una feature de la capa GeoJSON
    IO.inspect({layer_id, feature["properties"]}, label: "Feature mouseenter")
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:feature_mouseleave", %{"layerId" => layer_id}, socket) do
    # Evento cuando el mouse sale de una feature de la capa GeoJSON
    IO.inspect(layer_id, label: "Feature mouseleave")
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:feature_click", %{"layerId" => layer_id, "feature" => feature}, socket) do
    # Evento cuando se hace click en una feature de la capa GeoJSON
    IO.inspect({layer_id, feature["properties"]}, label: "Feature clicked")
    {:noreply, socket}
  end
end
