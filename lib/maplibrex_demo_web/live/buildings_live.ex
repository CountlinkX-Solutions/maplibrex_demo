defmodule MaplibrexDemoWeb.BuildingsLive do
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}
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
    <div class="relative w-full h-screen overflow-hidden bg-[#050810]">
      <%!-- Map full-screen --%>
      <.map
        id="buildings-map"
        center={[-74.006, 40.7128]}
        zoom={14}
        pitch={60}
        bearing={-17.6}
        style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
        class="absolute inset-0 w-full h-full"
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

      <%!-- Back nav --%>
      <div class="absolute top-[110px] left-4 z-20 flex flex-col gap-2">
        <a href="/" class="flex items-center gap-2 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-4 py-2 text-sm text-white/70 hover:text-white transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] no-underline">
          {gettext("Back to Demos")}
        </a>
        <div class="flex items-center gap-1 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-3 py-1.5">
          <a href={"/locale?locale=en&return_to=/buildings"} class={if @locale == "en", do: "text-[10px] font-semibold text-cyan-300 no-underline", else: "text-[10px] font-medium text-white/40 hover:text-white/70 no-underline"}>EN</a>
          <span class="text-white/20 text-[10px]">|</span>
          <a href={"/locale?locale=es&return_to=/buildings"} class={if @locale == "es", do: "text-[10px] font-semibold text-cyan-300 no-underline", else: "text-[10px] font-medium text-white/40 hover:text-white/70 no-underline"}>ES</a>
        </div>
      </div>

      <%!-- Control Panel --%>
      <div class="absolute top-4 right-4 bottom-16 w-72 z-20 overflow-y-auto">
        <div class="bg-[rgba(8,12,28,0.85)] backdrop-blur-xl border border-white/[0.09] rounded-2xl p-5 space-y-5">
          <%!-- Header --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-1">MaplibreX</p>
            <h2 class="text-base font-semibold text-white/95">{gettext("3D Buildings")}</h2>
            <p class="text-xs text-white/50 mt-1 leading-relaxed">{gettext("Extruded NYC building geometry with real-time height and color controls")}</p>
          </div>
          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Color Scheme --%>
          <div class="space-y-2">
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">{gettext("Color Scheme")}</p>
            <div class="space-y-1.5">
              <button
                phx-click="set_color_scheme"
                phx-value-scheme="height"
                class={if @color_scheme == "height",
                  do: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                  else: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"}
              >
                {gettext("By Height")}
              </button>
              <button
                phx-click="set_color_scheme"
                phx-value-scheme="uniform"
                class={if @color_scheme == "uniform",
                  do: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                  else: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"}
              >
                {gettext("Uniform Blue")}
              </button>
              <button
                phx-click="set_color_scheme"
                phx-value-scheme="type"
                class={if @color_scheme == "type",
                  do: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                  else: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"}
              >
                {gettext("By Type")}
              </button>
            </div>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Height Exaggeration slider --%>
          <div class="space-y-2">
            <div class="flex justify-between items-center">
              <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35">{gettext("Height Exaggeration")}</p>
              <span class="font-mono text-xs text-cyan-300/80">{Float.round(@height_exaggeration * 1.0, 1)}x</span>
            </div>
            <form phx-change="update_height">
              <input
                type="range"
                min="0.5"
                max="3.0"
                step="0.1"
                value={@height_exaggeration}
                name="value"
                class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
              />
            </form>
            <div class="flex justify-between text-[9px] text-white/25">
              <span>0.5x</span>
              <span>3.0x</span>
            </div>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Opacity slider --%>
          <div class="space-y-2">
            <div class="flex justify-between items-center">
              <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35">{gettext("Opacity")}</p>
              <span class="font-mono text-xs text-cyan-300/80">{trunc(@opacity * 100)}%</span>
            </div>
            <form phx-change="update_opacity">
              <input
                type="range"
                min="0.3"
                max="1.0"
                step="0.05"
                value={@opacity}
                name="value"
                class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
              />
            </form>
            <div class="flex justify-between text-[9px] text-white/25">
              <span>30%</span>
              <span>100%</span>
            </div>
          </div>
        </div>
      </div>

      <%!-- Telemetry bar --%>
      <div class="absolute bottom-4 left-4 z-20">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-xl px-4 py-3 flex items-center gap-4">
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Location")}</p>
            <p class="font-mono text-xs text-cyan-300/90">40.71, -74.01</p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Zoom")}</p>
            <p class="font-mono text-xs text-cyan-300/90">14</p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Height")}</p>
            <p class="font-mono text-xs text-cyan-300/90">{Float.round(@height_exaggeration * 1.0, 1)}x</p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Opacity")}</p>
            <p class="font-mono text-xs text-cyan-300/90">{trunc(@opacity * 100)}%</p>
          </div>
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

  @impl true
  def handle_event("layer:feature_mouseenter", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:feature_mouseleave", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:feature_click", _params, socket) do
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
