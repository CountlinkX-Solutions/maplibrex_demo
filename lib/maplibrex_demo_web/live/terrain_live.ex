defmodule MaplibrexDemoWeb.TerrainLive do
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}
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
    <div class="relative w-full h-screen overflow-hidden bg-[#050810]">
      <%!-- Map fills full screen --%>
      <.map
        id="terrain-map"
        center={[11.39085, 47.3]}
        zoom={12}
        pitch={72}
        bearing={0}
        style="https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json"
        class="absolute inset-0 w-full h-full"
      />

      <%!-- Navigation Control --%>
      <.navigation_control
        id="nav-control"
        map_id="terrain-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- RasterDEM Source for 3D terrain --%>
      <.raster_dem_source
        id="terrain-source"
        map_id="terrain-map"
        url="https://tiles.mapterhorn.com/tilejson.json"
      />

      <%!-- Separate RasterDEM Source for hillshade --%>
      <.raster_dem_source
        id="hillshade-source"
        map_id="terrain-map"
        url="https://tiles.mapterhorn.com/tilejson.json"
      />

      <%!-- Hillshade Layer --%>
      <.hillshade_layer
        id="hillshade"
        map_id="terrain-map"
        source_id="hillshade-source"
        paint={%{
          "hillshade-exaggeration" => 0.7,
          "hillshade-shadow-color" => "#004050",
          "hillshade-highlight-color" => "#ffffff",
          "hillshade-illumination-anchor" => "map"
        }}
      />

      <%!-- 3D Terrain --%>
      <%= if @terrain_enabled do %>
        <.terrain
          map_id="terrain-map"
          source_id="terrain-source"
          exaggeration={@exaggeration}
        />
      <% end %>

      <%!-- Back navigation pill --%>
      <div class="absolute top-[110px] left-4 z-20 flex flex-col gap-2">
        <a href="/" class="flex items-center gap-2 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-4 py-2 text-sm text-white/70 hover:text-white transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] no-underline">
          {gettext("Back to Demos")}
        </a>
        <div class="flex items-center gap-1 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-3 py-1.5">
          <a href={"/locale?locale=en&return_to=/terrain"} class={if @locale == "en", do: "text-[10px] font-semibold text-cyan-300 no-underline", else: "text-[10px] font-medium text-white/40 hover:text-white/70 no-underline"}>EN</a>
          <span class="text-white/20 text-[10px]">|</span>
          <a href={"/locale?locale=es&return_to=/terrain"} class={if @locale == "es", do: "text-[10px] font-semibold text-cyan-300 no-underline", else: "text-[10px] font-medium text-white/40 hover:text-white/70 no-underline"}>ES</a>
        </div>
      </div>

      <%!-- Control Panel --%>
      <div class="absolute top-4 right-4 bottom-16 w-72 z-20 overflow-y-auto">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-2xl p-5 space-y-5">
          <%!-- Title --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-1">
              MaplibreX
            </p>
            <h2 class="text-base font-semibold text-white">{gettext("3D Terrain")}</h2>
            <p class="text-xs text-white/50 mt-1">
              {gettext("Elevation rendering with DEM sources")}
            </p>
          </div>

          <div class="border-t border-white/[0.06]" />

          <%!-- Terrain toggle --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              {gettext("Terrain")}
            </p>
            <button
              phx-click="toggle_terrain"
              class={
                if @terrain_enabled,
                  do: "w-full text-left px-3 py-2.5 rounded-lg text-sm bg-cyan-500/10 border border-cyan-400/25 text-cyan-300 transition-all duration-300",
                  else: "w-full text-left px-3 py-2.5 rounded-lg text-sm bg-white/[0.05] border border-white/[0.07] text-white/60 transition-all duration-300"
              }
            >
              <span class="font-medium">{gettext("3D Terrain")}</span>
              <span class="ml-2 text-xs opacity-70">
                {if @terrain_enabled, do: gettext("Enabled"), else: gettext("Disabled")}
              </span>
            </button>
          </div>

          <div class="border-t border-white/[0.06]" />

          <%!-- Exaggeration slider --%>
          <div>
            <div class="flex items-center justify-between mb-2">
              <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35">
                {gettext("Exaggeration")}
              </p>
              <span class="font-mono text-xs text-cyan-300">
                {Float.round(@exaggeration * 1.0, 1)}x
              </span>
            </div>
            <form phx-change="update_exaggeration">
              <input
                type="range"
                min="0.5"
                max="3.0"
                step="0.1"
                value={@exaggeration}
                name="value"
                class="w-full accent-cyan-400"
              />
            </form>
            <div class="flex justify-between text-[10px] text-white/25 mt-1">
              <span>0.5x</span>
              <span>3.0x</span>
            </div>
          </div>

          <div class="border-t border-white/[0.06]" />

          <%!-- Location buttons --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              {gettext("Location")}
            </p>
            <div class="flex gap-2">
              <button
                onclick="document.getElementById('terrain-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [11.39085, 47.3], zoom: 12, pitch: 72, bearing: 0, duration: 1500}}))"
                class="flex-1 px-3 py-2 rounded-lg text-xs text-white/70 bg-white/[0.05] hover:bg-white/[0.10] border border-white/[0.07] transition-all duration-300 text-center"
              >
                Alps
              </button>
              <button
                onclick="document.getElementById('terrain-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [7.6586, 45.9763], zoom: 13, pitch: 72, bearing: 0, duration: 1500}}))"
                class="flex-1 px-3 py-2 rounded-lg text-xs text-white/70 bg-white/[0.05] hover:bg-white/[0.10] border border-white/[0.07] transition-all duration-300 text-center"
              >
                Matterhorn
              </button>
            </div>
          </div>
        </div>
      </div>

      <%!-- Telemetry panel --%>
      <div class="absolute bottom-4 left-4 z-20">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-xl px-4 py-3 flex items-center gap-4">
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Pitch")}</p>
            <p class="font-mono text-xs text-cyan-300">72°</p>
          </div>
          <div class="w-px h-6 bg-white/10" />
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Bearing")}</p>
            <p class="font-mono text-xs text-cyan-300">0°</p>
          </div>
          <div class="w-px h-6 bg-white/10" />
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Zoom")}</p>
            <p class="font-mono text-xs text-cyan-300">12</p>
          </div>
          <div class="w-px h-6 bg-white/10" />
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Exaggeration")}</p>
            <p class="font-mono text-xs text-cyan-300">{Float.round(@exaggeration * 1.0, 1)}x</p>
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
    exaggeration =
      case Float.parse(value) do
        {float_value, _} -> float_value
        :error -> 1.0
      end

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

  @impl true
  def handle_event("layer:added", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:removed", _params, socket) do
    {:noreply, socket}
  end
end
