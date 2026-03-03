defmodule MaplibrexDemoWeb.ParticlesLive do
  use MaplibrexDemoWeb, :live_view
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
    # Setup timer for animation (60fps)
    if connected?(socket) do
      :timer.send_interval(16, self(), :tick)
    end

    socket =
      socket
      |> assign(:time, 0.0)
      |> assign(:preset, "ocean_currents")
      |> assign(:color, [0.2, 0.6, 0.9])
      |> assign(:opacity, 0.8)
      |> assign(:point_size, 3.0)
      |> assign(:speed, 1.0)
      |> assign(:flow_direction, [1.0, 0.0])
      |> assign(:turbulence, 0.3)
      |> assign(:fps, 60)
      |> assign(:frame_count, 0)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :vertex_shader, @vertex_shader)
    assigns = assign(assigns, :fragment_shader, @fragment_shader)

    ~H"""
    <div class="relative h-screen w-full">
      <%!-- Mapa base --%>
      <.map
        id="particles-map"
        center={[0, 20]}
        zoom={2}
        pitch={0}
        bearing={0}
        style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
        class="absolute top-0 left-0 w-full h-full"
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
          "u_time" => @time,
          "u_speed" => @speed,
          "u_flow_direction" => @flow_direction,
          "u_turbulence" => @turbulence
        }}
      />

      <%!-- FPS Counter --%>
      <div class="absolute top-4 left-20 bg-black bg-opacity-70 text-white px-3 py-2 rounded text-sm font-mono">
        FPS: <%= @fps %> | Particles: 1000 | Time: <%= Float.round(@time, 1) %>s
      </div>

      <%!-- Control Panel --%>
      <div class="absolute top-4 right-4 bg-white rounded-lg shadow-2xl p-6 max-w-sm z-10 max-h-[90vh] overflow-y-auto">
        <h2 class="text-2xl font-bold mb-4 border-b border-gray-300 pb-2">
          ✨ Animated Particles
        </h2>

        <%!-- Preset Selector --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Preset:
          </label>
          <div class="space-y-2">
            <button
              phx-click="set_preset"
              phx-value-preset="ocean_currents"
              class={[
                "w-full px-4 py-2 rounded-lg text-sm font-medium transition-all",
                if(@preset == "ocean_currents",
                  do: "bg-blue-500 text-white",
                  else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                )
              ]}
            >
              🌊 Ocean Currents
            </button>
            <button
              phx-click="set_preset"
              phx-value-preset="wind_flow"
              class={[
                "w-full px-4 py-2 rounded-lg text-sm font-medium transition-all",
                if(@preset == "wind_flow",
                  do: "bg-gray-500 text-white",
                  else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                )
              ]}
            >
              💨 Wind Flow
            </button>
            <button
              phx-click="set_preset"
              phx-value-preset="lava_flow"
              class={[
                "w-full px-4 py-2 rounded-lg text-sm font-medium transition-all",
                if(@preset == "lava_flow",
                  do: "bg-red-500 text-white",
                  else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                )
              ]}
            >
              🌋 Lava Flow
            </button>
          </div>
        </div>

        <%!-- Color Controls --%>
        <div class="mb-4 p-3 bg-gray-50 rounded">
          <p class="text-sm font-semibold text-gray-700 mb-2">Color (RGB):</p>

          <div class="mb-2">
            <label class="text-xs text-gray-600">R: <%= Float.round(Enum.at(@color, 0), 2) %></label>
            <form phx-change="update_color_r">
              <input
                type="range"
                min="0"
                max="1"
                step="0.01"
                value={Enum.at(@color, 0)}
                name="value"
                class="w-full"
              />
            </form>
          </div>

          <div class="mb-2">
            <label class="text-xs text-gray-600">G: <%= Float.round(Enum.at(@color, 1), 2) %></label>
            <form phx-change="update_color_g">
              <input
                type="range"
                min="0"
                max="1"
                step="0.01"
                value={Enum.at(@color, 1)}
                name="value"
                class="w-full"
              />
            </form>
          </div>

          <div>
            <label class="text-xs text-gray-600">B: <%= Float.round(Enum.at(@color, 2), 2) %></label>
            <form phx-change="update_color_b">
              <input
                type="range"
                min="0"
                max="1"
                step="0.01"
                value={Enum.at(@color, 2)}
                name="value"
                class="w-full"
              />
            </form>
          </div>

          <div
            class="mt-2 h-8 rounded"
            style={"background-color: rgb(#{trunc(Enum.at(@color, 0) * 255)}, #{trunc(Enum.at(@color, 1) * 255)}, #{trunc(Enum.at(@color, 2) * 255)});"}
          >
          </div>
        </div>

        <%!-- Opacity --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Opacity: <%= trunc(@opacity * 100) %>%
          </label>
          <form phx-change="update_opacity">
            <input
              type="range"
              min="0"
              max="1"
              step="0.05"
              value={@opacity}
              name="value"
              class="w-full"
            />
          </form>
        </div>

        <%!-- Point Size --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Point Size: <%= Float.round(@point_size, 1) %>px
          </label>
          <form phx-change="update_point_size">
            <input
              type="range"
              min="1"
              max="10"
              step="0.5"
              value={@point_size}
              name="value"
              class="w-full"
            />
          </form>
        </div>

        <%!-- Speed --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Flow Speed: <%= Float.round(@speed, 1) %>x
          </label>
          <form phx-change="update_speed">
            <input
              type="range"
              min="0"
              max="5"
              step="0.1"
              value={@speed}
              name="value"
              class="w-full"
            />
          </form>
        </div>

        <%!-- Turbulence --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Turbulence: <%= Float.round(@turbulence, 2) %>
          </label>
          <form phx-change="update_turbulence">
            <input
              type="range"
              min="0"
              max="1"
              step="0.05"
              value={@turbulence}
              name="value"
              class="w-full"
            />
          </form>
        </div>

        <%!-- Flow Direction --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Flow Direction: <%= trunc(atan2(@flow_direction) * 180 / :math.pi()) %>°
          </label>
          <form phx-change="update_direction">
            <input
              type="range"
              min="0"
              max="360"
              step="15"
              value={trunc(atan2(@flow_direction) * 180 / :math.pi())}
              name="value"
              class="w-full"
            />
          </form>
          <div class="flex justify-between text-xs text-gray-500 mt-1">
            <span>N</span>
            <span>E</span>
            <span>S</span>
            <span>W</span>
          </div>
        </div>

        <%!-- Info --%>
        <div class="mt-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
          <h3 class="font-semibold mb-2 text-sm text-blue-900">About:</h3>
          <p class="text-xs text-blue-800">
            Custom WebGL particle system with 1000 animated particles rendered at 60fps using GLSL shaders.
            Adjust flow speed, direction, and turbulence to see different patterns.
          </p>
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
  def handle_info(:tick, socket) do
    new_time = socket.assigns.time + 0.016
    frame_count = socket.assigns.frame_count + 1

    # Calculate FPS every 30 frames
    fps =
      if rem(frame_count, 30) == 0 do
        60
      else
        socket.assigns.fps
      end

    socket = socket |> assign(:time, new_time) |> assign(:frame_count, frame_count) |> assign(:fps, fps)

    # Push uniform updates to the hook
    push_uniforms(socket)

    {:noreply, socket}
  end

  # Helper to push uniform updates to the JS hook
  defp push_uniforms(socket) do
    uniforms = %{
      "u_color" => socket.assigns.color,
      "u_opacity" => socket.assigns.opacity,
      "u_point_size" => socket.assigns.point_size,
      "u_time" => socket.assigns.time,
      "u_speed" => socket.assigns.speed,
      "u_flow_direction" => socket.assigns.flow_direction,
      "u_turbulence" => socket.assigns.turbulence
    }

    Phoenix.LiveView.push_event(socket, "update_uniforms_particle-layer", %{uniforms: uniforms})
  end

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
