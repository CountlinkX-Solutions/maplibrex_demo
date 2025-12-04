defmodule MaplibrexDemoWeb.MapLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:center, [-74.5, 40])
      |> assign(:zoom, 9)
      |> assign(:markers, [
        %{id: "marker-1", lng_lat: [-74.5, 40], color: "red", draggable: false},
        %{id: "marker-2", lng_lat: [-74.0, 40.5], color: "blue", draggable: true},
        %{id: "marker-3", lng_lat: [-73.5, 40.2], color: "green", draggable: false}
      ])

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

      <div class="mb-4 space-x-2">
        <button
          onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [-73.98, 40.75], zoom: 12, duration: 1000}}))"
          class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
        >
          Fly to NYC
        </button>

        <button
          onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:zoom_in'))"
          class="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600"
        >
          Zoom In
        </button>

        <button
          onclick="document.getElementById('demo-map').dispatchEvent(new CustomEvent('maplibrex:zoom_out'))"
          class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
        >
          Zoom Out
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

      <%!-- Marcadores --%>
      <%= for marker <- @markers do %>
        <.marker
          id={marker.id}
          map_id="demo-map"
          lng_lat={marker.lng_lat}
          color={marker.color}
          draggable={marker.draggable}
          popup_text={"Marker #{marker.id} - #{marker.color}"}
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
