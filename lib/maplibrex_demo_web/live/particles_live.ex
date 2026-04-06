defmodule MaplibrexDemoWeb.ParticlesLive do
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}
  import MaplibreX.Components

  # Animated Particle System Vertex Shader
  # Particles move according to flow direction, speed, and turbulence
  @vertex_shader """
  attribute vec2 a_position;
  uniform mat4 u_matrix;
  uniform float u_point_size;
  uniform float u_time;
  uniform float u_speed;
  uniform vec2 u_flow_direction;
  uniform float u_turbulence;

  // Simple noise function for turbulence
  float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
  }

  void main() {
    // Start with base position in Mercator [0, 1]
    vec2 pos = a_position;

    // Apply flow direction over time - DRAMATICALLY INCREASED for VISIBLE movement
    pos += u_flow_direction * u_time * u_speed * 0.003;  // 10x faster

    // Add turbulence for organic movement - DRAMATICALLY INCREASED
    float n = noise(pos * 100.0 + u_time * 2.0);  // Faster time variation
    pos += vec2(
      sin(pos.x * 20.0 + u_time * 5.0 + n) * u_turbulence * 0.005,  // 10x stronger, faster
      cos(pos.y * 20.0 + u_time * 5.0 + n) * u_turbulence * 0.005   // 10x stronger, faster
    );

    // Wrap coordinates to keep particles in [0, 1] Mercator range
    pos = fract(pos);

    // Transform to clip space using MapLibre's projection matrix
    gl_Position = u_matrix * vec4(pos, 0.0, 1.0);
    gl_PointSize = u_point_size;
  }
  """

  @fragment_shader """
  precision mediump float;

  uniform vec3 u_color;
  uniform float u_opacity;

  void main() {
    // Create circular particles with smooth edges
    vec2 center = gl_PointCoord - vec2(0.5);
    float dist = length(center);

    // Smooth fade at edges
    float alpha = 1.0 - smoothstep(0.3, 0.5, dist);

    gl_FragColor = vec4(u_color, alpha * u_opacity);
  }
  """

  @impl true
  def mount(_params, _session, socket) do
    # Animation is fully client-side via requestAnimationFrame / triggerRepaint in the hook.
    # The server only pushes uniforms when the user changes sliders.
    socket =
      socket
      |> assign(:preset, "ocean_currents")
      |> assign(:color, [0.2, 0.6, 0.9])
      |> assign(:opacity, 0.8)
      |> assign(:point_size, 3.0)
      |> assign(:speed, 1.0)
      |> assign(:flow_direction, [1.0, 0.0])
      |> assign(:turbulence, 0.3)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :vertex_shader, @vertex_shader)
    assigns = assign(assigns, :fragment_shader, @fragment_shader)

    ~H"""
    <div class="relative w-full h-screen overflow-hidden bg-[#050810]">
      <%!-- Map full-screen --%>
      <.map
        id="particles-map"
        center={[0, 20]}
        zoom={2}
        pitch={0}
        bearing={0}
        style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
        class="absolute inset-0 w-full h-full"
      />

      <%!-- Navigation Control --%>
      <.navigation_control
        id="nav-control"
        map_id="particles-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- Custom WebGL Particle Layer --%>
      <.custom_layer
        id="particle-layer"
        map_id="particles-map"
        vertex_shader={@vertex_shader}
        fragment_shader={@fragment_shader}
        uniforms={%{
          "u_color" => @color,
          "u_opacity" => @opacity,
          "u_point_size" => @point_size,
          "u_time" => 0.0,
          "u_speed" => @speed,
          "u_flow_direction" => @flow_direction,
          "u_turbulence" => @turbulence
        }}
      />

      <%!-- Back nav pill --%>
      <div class="absolute top-[110px] left-4 z-20 flex flex-col gap-2">
        <a href="/" class="flex items-center gap-2 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-4 py-2 text-sm text-white/70 hover:text-white transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] no-underline">
          {gettext("Back to Demos")}
        </a>
        <div class="flex items-center gap-1 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-3 py-1.5">
          <a href={"/locale?locale=en&return_to=/particles"} class={if @locale == "en", do: "text-[10px] font-semibold text-cyan-300 no-underline", else: "text-[10px] font-medium text-white/40 hover:text-white/70 no-underline"}>EN</a>
          <span class="text-white/20 text-[10px]">|</span>
          <a href={"/locale?locale=es&return_to=/particles"} class={if @locale == "es", do: "text-[10px] font-semibold text-cyan-300 no-underline", else: "text-[10px] font-medium text-white/40 hover:text-white/70 no-underline"}>ES</a>
        </div>
      </div>

      <%!-- Control Panel --%>
      <div class="absolute top-4 right-4 bottom-16 w-72 z-20 overflow-y-auto">
        <div class="bg-[rgba(8,12,28,0.85)] backdrop-blur-xl border border-white/[0.09] rounded-2xl p-5 space-y-5">
          <%!-- Header --%>
          <div>
            <h2 class="text-sm font-semibold text-white tracking-wide">{gettext("WebGL Particles")}</h2>
            <p class="text-[11px] text-white/40 mt-0.5 leading-relaxed">
              {gettext("1,000 particles animated via custom GLSL vertex & fragment shaders")}
            </p>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Preset --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              {gettext("Preset")}
            </p>
            <div class="space-y-1.5">
              <button
                phx-click="set_preset"
                phx-value-preset="ocean_currents"
                class={
                  if @preset == "ocean_currents",
                    do:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                    else:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300"
                }
              >
                {gettext("Ocean Currents")}
              </button>
              <button
                phx-click="set_preset"
                phx-value-preset="wind_flow"
                class={
                  if @preset == "wind_flow",
                    do:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                    else:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300"
                }
              >
                {gettext("Wind Flow")}
              </button>
              <button
                phx-click="set_preset"
                phx-value-preset="lava_flow"
                class={
                  if @preset == "lava_flow",
                    do:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                    else:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300"
                }
              >
                {gettext("Lava Flow")}
              </button>
            </div>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Particle Color --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-3">
              {gettext("Particle Color")}
            </p>
            <%!-- Color preview swatch --%>
            <div
              class="h-6 rounded-lg mb-3 border border-white/[0.07]"
              style={"background-color: rgb(#{trunc(Enum.at(@color, 0) * 255)}, #{trunc(Enum.at(@color, 1) * 255)}, #{trunc(Enum.at(@color, 2) * 255)});"}
            >
            </div>
            <div class="space-y-3">
              <div>
                <div class="flex items-center justify-between mb-1">
                  <p class="text-[9px] uppercase tracking-widest text-white/35">R</p>
                  <p class="font-mono text-[10px] text-white/50">
                    {Float.round(Enum.at(@color, 0), 2)}
                  </p>
                </div>
                <form phx-change="update_color_r">
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.01"
                    value={Enum.at(@color, 0)}
                    name="value"
                    class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
                  />
                </form>
              </div>
              <div>
                <div class="flex items-center justify-between mb-1">
                  <p class="text-[9px] uppercase tracking-widest text-white/35">G</p>
                  <p class="font-mono text-[10px] text-white/50">
                    {Float.round(Enum.at(@color, 1), 2)}
                  </p>
                </div>
                <form phx-change="update_color_g">
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.01"
                    value={Enum.at(@color, 1)}
                    name="value"
                    class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
                  />
                </form>
              </div>
              <div>
                <div class="flex items-center justify-between mb-1">
                  <p class="text-[9px] uppercase tracking-widest text-white/35">B</p>
                  <p class="font-mono text-[10px] text-white/50">
                    {Float.round(Enum.at(@color, 2), 2)}
                  </p>
                </div>
                <form phx-change="update_color_b">
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.01"
                    value={Enum.at(@color, 2)}
                    name="value"
                    class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
                  />
                </form>
              </div>
            </div>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Flow Parameters --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-3">
              {gettext("Flow Parameters")}
            </p>
            <div class="space-y-3">
              <div>
                <div class="flex items-center justify-between mb-1">
                  <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Speed")}</p>
                  <p class="font-mono text-[10px] text-white/50">{Float.round(@speed, 1)}x</p>
                </div>
                <form phx-change="update_speed">
                  <input
                    type="range"
                    min="0"
                    max="5"
                    step="0.1"
                    value={@speed}
                    name="value"
                    class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
                  />
                </form>
              </div>
              <div>
                <div class="flex items-center justify-between mb-1">
                  <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Turbulence")}</p>
                  <p class="font-mono text-[10px] text-white/50">{Float.round(@turbulence, 2)}</p>
                </div>
                <form phx-change="update_turbulence">
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.05"
                    value={@turbulence}
                    name="value"
                    class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
                  />
                </form>
              </div>
              <div>
                <div class="flex items-center justify-between mb-1">
                  <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Direction")}</p>
                  <p class="font-mono text-[10px] text-white/50">
                    {trunc(atan2(@flow_direction) * 180 / :math.pi())}deg
                  </p>
                </div>
                <form phx-change="update_direction">
                  <input
                    type="range"
                    min="0"
                    max="360"
                    step="15"
                    value={trunc(atan2(@flow_direction) * 180 / :math.pi())}
                    name="value"
                    class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
                  />
                </form>
                <div class="flex justify-between text-[9px] text-white/25 mt-1">
                  <span>N</span><span>E</span><span>S</span><span>W</span>
                </div>
              </div>
            </div>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Render --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-3">
              {gettext("Render")}
            </p>
            <div class="space-y-3">
              <div>
                <div class="flex items-center justify-between mb-1">
                  <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Opacity")}</p>
                  <p class="font-mono text-[10px] text-white/50">{trunc(@opacity * 100)}%</p>
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
              </div>
              <div>
                <div class="flex items-center justify-between mb-1">
                  <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Size")}</p>
                  <p class="font-mono text-[10px] text-white/50">
                    {Float.round(@point_size, 1)}px
                  </p>
                </div>
                <form phx-change="update_point_size">
                  <input
                    type="range"
                    min="1"
                    max="10"
                    step="0.5"
                    value={@point_size}
                    name="value"
                    class="w-full h-1 rounded-full bg-white/10 appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-cyan-400 [&::-webkit-slider-thumb]:cursor-pointer"
                  />
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- Telemetry --%>
      <div class="absolute bottom-4 left-4 z-20">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-xl px-4 py-3 flex items-center gap-4">
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("FPS")}</p>
            <p class="font-mono text-xs text-cyan-300/90">60</p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Preset")}</p>
            <p class="font-mono text-xs text-cyan-300/90">
              {case @preset do
                "ocean_currents" -> gettext("Ocean")
                "wind_flow" -> gettext("Wind")
                "lava_flow" -> gettext("Lava")
                other -> other
              end}
            </p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Particles")}</p>
            <p class="font-mono text-xs text-cyan-300/90">{gettext("1,000")}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper function to calculate angle from direction vector
  defp atan2(flow_direction) do
    [x, y] = flow_direction
    :math.atan2(y, x)
  end

  # Event Handlers

  @impl true
  def handle_event("set_preset", %{"preset" => preset}, socket) do
    socket =
      case preset do
        "ocean_currents" ->
          socket
          |> assign(:preset, preset)
          |> assign(:color, [0.2, 0.6, 0.9])
          |> assign(:opacity, 0.8)
          |> assign(:point_size, 3.0)
          |> assign(:speed, 1.0)
          |> assign(:turbulence, 0.3)
          |> assign(:flow_direction, [1.0, 0.0])

        "wind_flow" ->
          socket
          |> assign(:preset, preset)
          |> assign(:color, [0.9, 0.9, 0.9])
          |> assign(:opacity, 0.6)
          |> assign(:point_size, 2.0)
          |> assign(:speed, 2.5)
          |> assign(:turbulence, 0.7)
          |> assign(:flow_direction, [0.7, 0.7])

        "lava_flow" ->
          socket
          |> assign(:preset, preset)
          |> assign(:color, [1.0, 0.3, 0.1])
          |> assign(:opacity, 0.9)
          |> assign(:point_size, 4.0)
          |> assign(:speed, 0.5)
          |> assign(:turbulence, 0.9)
          |> assign(:flow_direction, [0.0, -1.0])

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_color_r", %{"value" => value}, socket) do
    r = parse_float(value, 0.5)
    [_old_r, g, b] = socket.assigns.color
    {:noreply, assign(socket, :color, [r, g, b])}
  end

  @impl true
  def handle_event("update_color_g", %{"value" => value}, socket) do
    g = parse_float(value, 0.5)
    [r, _old_g, b] = socket.assigns.color
    {:noreply, assign(socket, :color, [r, g, b])}
  end

  @impl true
  def handle_event("update_color_b", %{"value" => value}, socket) do
    b = parse_float(value, 0.5)
    [r, g, _old_b] = socket.assigns.color
    {:noreply, assign(socket, :color, [r, g, b])}
  end

  @impl true
  def handle_event("update_opacity", %{"value" => value}, socket) do
    {:noreply, assign(socket, :opacity, parse_float(value, 0.8))}
  end

  @impl true
  def handle_event("update_point_size", %{"value" => value}, socket) do
    {:noreply, assign(socket, :point_size, parse_float(value, 3.0))}
  end

  @impl true
  def handle_event("update_speed", %{"value" => value}, socket) do
    {:noreply, assign(socket, :speed, parse_float(value, 1.0))}
  end

  @impl true
  def handle_event("update_turbulence", %{"value" => value}, socket) do
    {:noreply, assign(socket, :turbulence, parse_float(value, 0.3))}
  end

  @impl true
  def handle_event("update_direction", %{"value" => value}, socket) do
    angle_deg = parse_float(value, 0.0)
    angle_rad = angle_deg * :math.pi() / 180.0
    direction = [:math.cos(angle_rad), :math.sin(angle_rad)]
    {:noreply, assign(socket, :flow_direction, direction)}
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

  defp parse_float(value, default) do
    case Float.parse(value) do
      {float_value, _} -> float_value
      :error -> default
    end
  end
end
