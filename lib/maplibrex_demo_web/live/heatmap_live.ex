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
    <div class="relative w-full h-screen overflow-hidden bg-[#050810]">
      <%!-- Map full-screen --%>
      <.map
        id="heatmap-map"
        center={[-98.5, 39.8]}
        zoom={3.5}
        pitch={0}
        bearing={0}
        style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
        class="absolute inset-0 w-full h-full"
      />

      <%!-- Navigation Control --%>
      <.navigation_control
        id="nav-control"
        map_id="heatmap-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- Heatmap Layer --%>
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

      <%!-- Back nav --%>
      <div class="absolute top-14 left-4 z-20">
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
            <h2 class="text-base font-semibold text-white/95">Heatmap</h2>
            <p class="text-xs text-white/50 mt-1 leading-relaxed">500-point earthquake density visualization across the US</p>
          </div>
          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Radius slider --%>
          <div class="space-y-2">
            <div class="flex justify-between items-center">
              <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35">Radius</p>
              <span class="font-mono text-xs text-cyan-300/80">{@radius}px</span>
            </div>
            <form phx-change="update_radius">
              <input
                type="range"
                min="10"
                max="50"
                step="1"
                value={@radius}
                name="value"
                class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
              />
            </form>
            <div class="flex justify-between text-[9px] text-white/25">
              <span>10px</span>
              <span>50px</span>
            </div>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Intensity slider --%>
          <div class="space-y-2">
            <div class="flex justify-between items-center">
              <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35">Intensity</p>
              <span class="font-mono text-xs text-cyan-300/80">{Float.round(@intensity * 1.0, 1)}x</span>
            </div>
            <form phx-change="update_intensity">
              <input
                type="range"
                min="0.5"
                max="3.0"
                step="0.1"
                value={@intensity}
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
              <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35">Opacity</p>
              <span class="font-mono text-xs text-cyan-300/80">{trunc(@opacity * 100)}%</span>
            </div>
            <form phx-change="update_opacity">
              <input
                type="range"
                min="0"
                max="1"
                step="0.05"
                value={@opacity}
                name="value"
                class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
              />
            </form>
            <div class="flex justify-between text-[9px] text-white/25">
              <span>0%</span>
              <span>100%</span>
            </div>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Gradient legend --%>
          <div class="space-y-2">
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35">Gradient</p>
            <div class="h-2 rounded-full" style="background: linear-gradient(to right, rgba(33,102,172,0), rgb(103,169,207), rgb(209,229,240), rgb(253,219,199), rgb(239,138,98), rgb(178,24,43));"></div>
            <div class="flex justify-between text-[9px] text-white/25">
              <span>Low</span>
              <span>High</span>
            </div>
          </div>
        </div>
      </div>

      <%!-- Telemetry bar --%>
      <div class="absolute bottom-4 left-4 z-20">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-xl px-4 py-3 flex items-center gap-4">
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">Points</p>
            <p class="font-mono text-xs text-cyan-300/90">500 points</p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">Radius</p>
            <p class="font-mono text-xs text-cyan-300/90">{@radius}px</p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">Intensity</p>
            <p class="font-mono text-xs text-cyan-300/90">{Float.round(@intensity * 1.0, 1)}x</p>
          </div>
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
