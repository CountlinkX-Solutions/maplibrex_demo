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
    assigns =
      assigns
      |> assign(:vertex_shader, @vertex_shader)
      |> assign(:fragment_shader, @fragment_shader)

    ~H"""
    <.demo_page
      path={~p"/particles"}
      locale={@locale}
      title={gettext("WebGL Particles")}
      subtitle={gettext("1,000 particles animated via custom GLSL vertex & fragment shaders")}
    >
      <:map>
        <.map
          id="particles-map"
          center={[0, 20]}
          zoom={2}
          pitch={0}
          bearing={0}
          style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
          class="absolute inset-0 h-full w-full"
        />

        <.navigation_control id="nav-control" map_id="particles-map" position="top-left" />

        <.custom_layer
          id="particle-layer"
          map_id="particles-map"
          vertex_shader={@vertex_shader}
          fragment_shader={@fragment_shader}
          uniforms={uniforms(assigns)}
        />
      </:map>

      <:panel>
        <.panel_section label={gettext("Preset")} class="space-y-1.5">
          <.option_button
            :for={{id, _values} <- presets()}
            active={@preset == id}
            phx-click="set_preset"
            phx-value-id={id}
          >
            {preset_label(id)}
          </.option_button>
        </.panel_section>

        <.panel_section label={gettext("Particle Color")}>
          <div
            class="mb-3 h-6 rounded-lg border border-white/[0.07]"
            style={"background-color: #{css_color(@color)}"}
          />
          <div class="space-y-3">
            <.slider
              label="R"
              name="value"
              value={Enum.at(@color, 0)}
              min="0"
              max="1"
              step="0.01"
              on_change="update_color_r"
              display={to_string(Float.round(Enum.at(@color, 0), 2))}
            />
            <.slider
              label="G"
              name="value"
              value={Enum.at(@color, 1)}
              min="0"
              max="1"
              step="0.01"
              on_change="update_color_g"
              display={to_string(Float.round(Enum.at(@color, 1), 2))}
            />
            <.slider
              label="B"
              name="value"
              value={Enum.at(@color, 2)}
              min="0"
              max="1"
              step="0.01"
              on_change="update_color_b"
              display={to_string(Float.round(Enum.at(@color, 2), 2))}
            />
          </div>
        </.panel_section>

        <.panel_section label={gettext("Flow Parameters")} class="space-y-3">
          <.slider
            label={gettext("Speed")}
            name="value"
            value={@speed}
            min="0"
            max="5"
            step="0.1"
            on_change="update_speed"
            display={"#{Float.round(@speed, 1)}x"}
          />
          <.slider
            label={gettext("Turbulence")}
            name="value"
            value={@turbulence}
            min="0"
            max="1"
            step="0.05"
            on_change="update_turbulence"
            display={to_string(Float.round(@turbulence, 2))}
          />
          <div>
            <.slider
              label={gettext("Direction")}
              name="value"
              value={direction_degrees(@flow_direction)}
              min="0"
              max="360"
              step="15"
              on_change="update_direction"
              display={"#{direction_degrees(@flow_direction)}°"}
            />
            <div class="mt-1 flex justify-between text-[9px] text-white/25">
              <span>N</span><span>E</span><span>S</span><span>W</span>
            </div>
          </div>
        </.panel_section>

        <.panel_section label={gettext("Render")} class="space-y-3">
          <.slider
            label={gettext("Opacity")}
            name="value"
            value={@opacity}
            min="0"
            max="1"
            step="0.05"
            on_change="update_opacity"
            display={"#{trunc(@opacity * 100)}%"}
          />
          <.slider
            label={gettext("Size")}
            name="value"
            value={@point_size}
            min="1"
            max="10"
            step="0.5"
            on_change="update_point_size"
            display={"#{Float.round(@point_size, 1)}px"}
          />
        </.panel_section>
      </:panel>

      <:telemetry>
        <.stat first label={gettext("Preset")} value={preset_label(@preset)} />
        <.stat label={gettext("Particles")} value="1,000" />
        <.stat label={gettext("Shader")} value="GLSL" />
      </:telemetry>
    </.demo_page>
    """
  end

  # Uniform values handed to the custom WebGL layer.
  defp uniforms(assigns) do
    %{
      "u_color" => assigns.color,
      "u_opacity" => assigns.opacity,
      "u_point_size" => assigns.point_size,
      "u_time" => 0.0,
      "u_speed" => assigns.speed,
      "u_flow_direction" => assigns.flow_direction,
      "u_turbulence" => assigns.turbulence
    }
  end

  defp css_color([r, g, b]) do
    "rgb(#{trunc(r * 255)}, #{trunc(g * 255)}, #{trunc(b * 255)})"
  end

  defp direction_degrees([x, y]) do
    :math.atan2(y, x) |> Kernel.*(180) |> Kernel./(:math.pi()) |> trunc()
  end

  defp preset_label("ocean_currents"), do: gettext("Ocean Currents")
  defp preset_label("wind_flow"), do: gettext("Wind Flow")
  defp preset_label("lava_flow"), do: gettext("Lava Flow")
  defp preset_label(other), do: other

  # Event Handlers

  # Each preset is just a set of uniform values; the shader itself never changes.
  defp presets do
    %{
      "ocean_currents" => %{
        color: [0.2, 0.6, 0.9],
        opacity: 0.8,
        point_size: 3.0,
        speed: 1.0,
        turbulence: 0.3,
        flow_direction: [1.0, 0.0]
      },
      "wind_flow" => %{
        color: [0.9, 0.9, 0.9],
        opacity: 0.6,
        point_size: 2.0,
        speed: 2.5,
        turbulence: 0.7,
        flow_direction: [0.7, 0.7]
      },
      "lava_flow" => %{
        color: [1.0, 0.3, 0.1],
        opacity: 0.9,
        point_size: 4.0,
        speed: 0.5,
        turbulence: 0.9,
        flow_direction: [0.0, -1.0]
      }
    }
  end

  @impl true
  def handle_event("set_preset", %{"id" => preset}, socket) do
    case Map.fetch(presets(), preset) do
      {:ok, values} ->
        socket =
          Enum.reduce(values, assign(socket, :preset, preset), fn {key, value}, acc ->
            assign(acc, key, value)
          end)

        {:noreply, push_uniforms(socket)}

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("update_color_r", %{"value" => value}, socket) do
    r = parse_float(value, 0.5)
    [_old_r, g, b] = socket.assigns.color
    socket = assign(socket, :color, [r, g, b])
    {:noreply, push_uniforms(socket)}
  end

  def handle_event("update_color_g", %{"value" => value}, socket) do
    g = parse_float(value, 0.5)
    [r, _old_g, b] = socket.assigns.color
    socket = assign(socket, :color, [r, g, b])
    {:noreply, push_uniforms(socket)}
  end

  def handle_event("update_color_b", %{"value" => value}, socket) do
    b = parse_float(value, 0.5)
    [r, g, _old_b] = socket.assigns.color
    socket = assign(socket, :color, [r, g, b])
    {:noreply, push_uniforms(socket)}
  end

  def handle_event("update_opacity", %{"value" => value}, socket) do
    socket = assign(socket, :opacity, parse_float(value, 0.8))
    {:noreply, push_uniforms(socket)}
  end

  def handle_event("update_point_size", %{"value" => value}, socket) do
    socket = assign(socket, :point_size, parse_float(value, 3.0))
    {:noreply, push_uniforms(socket)}
  end

  def handle_event("update_speed", %{"value" => value}, socket) do
    socket = assign(socket, :speed, parse_float(value, 1.0))
    {:noreply, push_uniforms(socket)}
  end

  def handle_event("update_turbulence", %{"value" => value}, socket) do
    socket = assign(socket, :turbulence, parse_float(value, 0.3))
    {:noreply, push_uniforms(socket)}
  end

  def handle_event("update_direction", %{"value" => value}, socket) do
    angle_deg = parse_float(value, 0.0)
    angle_rad = angle_deg * :math.pi() / 180.0
    direction = [:math.cos(angle_rad), :math.sin(angle_rad)]
    socket = assign(socket, :flow_direction, direction)
    {:noreply, push_uniforms(socket)}
  end

  def handle_event("map:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("layer:" <> _, _params, socket), do: {:noreply, socket}

  # Helper Functions

  # Push current shader uniforms to the hook via Phoenix event channel.
  # This is more reliable than relying on DOM-patching (updated() hook callback)
  # because it uses the LiveView websocket directly.
  defp push_uniforms(socket) do
    a = socket.assigns

    push_event(socket, "update_uniforms_particle-layer", %{
      uniforms: %{
        "u_color" => a.color,
        "u_opacity" => a.opacity,
        "u_point_size" => a.point_size,
        "u_time" => 0.0,
        "u_speed" => a.speed,
        "u_flow_direction" => a.flow_direction,
        "u_turbulence" => a.turbulence
      }
    })
  end

  defp parse_float(value, default) do
    case Float.parse(value) do
      {float_value, _} -> float_value
      :error -> default
    end
  end
end
