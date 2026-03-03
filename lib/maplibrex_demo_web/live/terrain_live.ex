defmodule MaplibrexDemoWeb.TerrainLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:terrain_enabled, true)
      |> assign(:exaggeration, 1.5)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative h-screen w-full">
      <%!-- Mapa con terreno 3D --%>
      <.map
        id="terrain-map"
        center={[11.39085, 47.3]}
        zoom={12}
        pitch={72}
        bearing={0}
        style="https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json"
        class="absolute top-0 left-0 w-full h-full"
      />

      <%!-- Navigation Control --%>
      <.navigation_control
        id="nav-control"
        map_id="terrain-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- RasterDEM Source para terreno --%>
      <.raster_dem_source
        id="terrain-source"
        map_id="terrain-map"
        url="https://tiles.mapterhorn.com/tilejson.json"
      />

      <%!-- Terreno 3D --%>
      <%= if @terrain_enabled do %>
        <.terrain
          map_id="terrain-map"
          source_id="terrain-source"
          exaggeration={@exaggeration}
        />
      <% end %>

      <%!-- Panel de Control --%>
      <div class="absolute top-4 right-4 bg-white rounded-lg shadow-2xl p-6 max-w-sm z-10">
        <h2 class="text-2xl font-bold mb-4 border-b border-gray-300 pb-2">
          🏔️ 3D Terrain Demo
        </h2>

        <%!-- Toggle Terrain --%>
        <div class="mb-4 p-4 bg-gray-50 rounded-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="font-semibold">Terrain 3D</span>
            <button
              phx-click="toggle_terrain"
              class={[
                "px-4 py-2 rounded-lg font-medium transition-all",
                if(@terrain_enabled,
                  do: "bg-green-500 text-white hover:bg-green-600",
                  else: "bg-gray-300 text-gray-700 hover:bg-gray-400"
                )
              ]}
            >
              <%= if @terrain_enabled, do: "ON", else: "OFF" %>
            </button>
          </div>

          <%= if @terrain_enabled do %>
            <div class="mt-3">
              <label class="block text-sm text-gray-600 mb-1">
                Exaggeration: <%= @exaggeration %>x
              </label>
              <form phx-change="update_exaggeration">
                <input
                  type="range"
                  min="0.5"
                  max="3.0"
                  step="0.1"
                  value={@exaggeration}
                  name="value"
                  class="w-full"
                />
              </form>
              <div class="flex justify-between text-xs text-gray-500 mt-1">
                <span>0.5x</span>
                <span>3.0x</span>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Info --%>
        <div class="mt-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
          <h3 class="font-semibold mb-2 text-sm text-blue-900">About:</h3>
          <p class="text-xs text-blue-800">
            This demo shows MapLibre's 3D terrain rendering with digital elevation models (DEM).
            Adjust the exaggeration to see dramatic terrain effects on this view of the Alps.
          </p>
        </div>

        <%!-- Camera Info --%>
        <div class="mt-4 pt-4 border-t border-gray-300 text-xs text-gray-600">
          <div class="grid grid-cols-2 gap-2">
            <div>
              <span class="font-semibold">Pitch:</span> 72°
            </div>
            <div>
              <span class="font-semibold">Bearing:</span> 0°
            </div>
            <div>
              <span class="font-semibold">Zoom:</span> 12
            </div>
            <div>
              <span class="font-semibold">Location:</span> Alps
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_terrain", _params, socket) do
    {:noreply, assign(socket, :terrain_enabled, !socket.assigns.terrain_enabled)}
  end

  @impl true
  def handle_event("update_exaggeration", %{"value" => value}, socket) do
    exaggeration = String.to_float(value)
    {:noreply, assign(socket, :exaggeration, exaggeration)}
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
  def handle_event("source:added", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("source:removed", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("source:error", %{"error" => error}, socket) do
    IO.inspect(error, label: "Source error")
    {:noreply, socket}
  end

  @impl true
  def handle_event("source:data", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("terrain:enabled", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("terrain:disabled", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("sky:added", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("sky:removed", _params, socket) do
    {:noreply, socket}
  end
end
