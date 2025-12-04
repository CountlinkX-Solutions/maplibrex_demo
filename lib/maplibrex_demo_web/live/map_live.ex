defmodule MaplibrexDemoWeb.MapLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:center, [-74.5, 40])
      |> assign(:zoom, 9)
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
    <div class="p-8">
      <h1 class="text-3xl font-bold mb-4">MaplibreX Demo</h1>

      <div class="mb-4">
        <p class="text-gray-600">
          Demo completo de MaplibreX integrado con Phoenix LiveView
        </p>
      </div>

      <%!-- Selector de Estilos --%>
      <div class="mb-4 flex items-center gap-4">
        <label class="font-semibold text-gray-700">Estilo del Mapa:</label>
        <%= for style <- @map_styles do %>
          <button
            onclick={"document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:set_style', {detail: {style: '#{style.url}'}}))"}
            phx-click="update_style"
            phx-value-url={style.url}
            class={"px-4 py-2 rounded transition-colors #{if @current_style == style.url, do: "bg-purple-600 text-white", else: "bg-gray-200 hover:bg-gray-300"}"}
          >
            <%= style.name %>
          </button>
        <% end %>
      </div>

      <%!-- Controles de Navegación --%>
      <div class="mb-4 space-x-2">
        <button
          onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [-73.98, 40.75], zoom: 12, duration: 1000}}))"
          class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
        >
          🗽 Fly to NYC
        </button>

        <button
          onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [-118.24, 34.05], zoom: 12, duration: 1500}}))"
          class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
        >
          🌴 Fly to LA
        </button>

        <button
          onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:zoom_in'))"
          class="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600"
        >
          ➕ Zoom In
        </button>

        <button
          onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:zoom_out'))"
          class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
        >
          ➖ Zoom Out
        </button>

        <button
          onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:reset_north'))"
          class="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-600"
        >
          🧭 Reset North
        </button>
      </div>

      <%!-- Controles de Marcadores --%>
      <div class="mb-4 space-x-2">
        <button
          phx-click="add_marker"
          class="bg-indigo-500 text-white px-4 py-2 rounded hover:bg-indigo-600"
        >
          📍 Agregar Marcador
        </button>

        <button
          phx-click="clear_markers"
          class="bg-orange-500 text-white px-4 py-2 rounded hover:bg-orange-600"
        >
          🗑️ Limpiar Marcadores
        </button>

        <button
          phx-click="toggle_geojson"
          class={"px-4 py-2 rounded transition-colors #{if @show_geojson, do: "bg-purple-600 text-white hover:bg-purple-700", else: "bg-gray-400 text-white hover:bg-gray-500"}"}
        >
          <%= if @show_geojson, do: "🗺️ GeoJSON: ON", else: "🗺️ GeoJSON: OFF" %>
        </button>

        <button
          onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [-74.5, 40], zoom: 9, duration: 1500}}))"
          class="bg-teal-500 text-white px-4 py-2 rounded hover:bg-teal-600"
        >
          🏠 Reset View
        </button>
      </div>

      <%!-- Mapa principal --%>
      <.map
        id="demo-map"
        center={@center}
        zoom={@zoom}
        style="https://demotiles.maplibre.org/style.json"
        class="w-full h-96 rounded-lg shadow-lg"
      />

      <%!-- Controles Nativos del Mapa --%>
      <.navigation_control
        id="nav-control"
        map_id="demo-map"
        position="top-right"
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

      <%!-- Marcadores --%>
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

      <%!-- Estado --%>
      <div class="mt-4 p-4 bg-gray-100 rounded">
        <h3 class="font-bold mb-2">Estado del Mapa:</h3>
        <p><strong>Centro:</strong> <%= inspect(@center) %></p>
        <p><strong>Zoom:</strong> <%= @zoom %></p>
        <p><strong>Marcadores:</strong> <%= length(@markers) %></p>
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
  def handle_event("map:zoom_changed", _params, socket) do
    # La librería envía este evento pero no lo manejamos para evitar re-renders
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:moved", _params, socket) do
    # NO actualizamos assigns para evitar re-renders que destruyen el mapa
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
end
