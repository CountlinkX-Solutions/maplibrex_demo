defmodule MaplibrexDemoWeb.Scenarios.ParticlesScenario do
  @moduledoc """
  WebGL particles: a `<.custom_layer>` that draws 1,000 particles with the
  GLSL shaders below, moved by uniforms set from the server.

  MaplibreX places the particles at random over the world and, because the
  uniforms include `u_time`, advances that uniform in the browser on every
  frame. Everything else the shaders read (colour, speed, turbulence,
  direction, size, opacity) is an assign: a preset or a slider changes the
  assigns, and the layer reads the new uniforms on its next frame.

  In MaplibreX 0.1 a custom layer's `uniforms` attribute is rendered when
  the layer mounts and not again, so a later change does not reach the
  browser by itself. The layer's hook also listens for
  `"update_uniforms_<id>"`, and this scenario pushes every change there.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and reports each map event to the page.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @vertex_shader """
  attribute vec2 a_position;
  uniform mat4 u_matrix;
  uniform float u_point_size;
  uniform float u_time;
  uniform float u_speed;
  uniform vec2 u_flow_direction;
  uniform float u_turbulence;

  // A cheap pseudo-random value from a position.
  float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
  }

  void main() {
    // Positions are MapLibre's Mercator coordinates, from 0 to 1.
    vec2 pos = a_position + u_flow_direction * u_time * u_speed * 0.003;

    // Turbulence bends each particle's path with a wave of its own phase.
    float n = noise(pos * 100.0 + u_time * 2.0);
    pos += vec2(
      sin(pos.x * 20.0 + u_time * 5.0 + n),
      cos(pos.y * 20.0 + u_time * 5.0 + n)
    ) * u_turbulence * 0.005;

    // A particle that leaves the world comes back on the other side.
    pos = fract(pos);

    gl_Position = u_matrix * vec4(pos, 0.0, 1.0);
    gl_PointSize = u_point_size;
  }
  """

  @fragment_shader """
  precision mediump float;

  uniform vec3 u_color;
  uniform float u_opacity;

  void main() {
    // A round particle with a soft edge.
    float dist = length(gl_PointCoord - vec2(0.5));
    float alpha = 1.0 - smoothstep(0.3, 0.5, dist);

    gl_FragColor = vec4(u_color, alpha * u_opacity);
  }
  """

  # Each preset is a set of uniform values; the shaders stay the same. The
  # direction is a compass bearing: 0 is north, 90 east.
  @presets [
    {"ocean_currents",
     %{
       color: [0.2, 0.6, 0.9],
       speed: 1.0,
       turbulence: 0.3,
       direction: 90,
       point_size: 3.0,
       opacity: 0.8
     }},
    {"wind_flow",
     %{
       color: [0.9, 0.9, 0.9],
       speed: 2.5,
       turbulence: 0.7,
       direction: 135,
       point_size: 2.0,
       opacity: 0.6
     }},
    {"lava_flow",
     %{
       color: [1.0, 0.3, 0.1],
       speed: 0.5,
       turbulence: 0.9,
       direction: 0,
       point_size: 4.0,
       opacity: 0.9
     }}
  ]

  @colors [
    {"blue", [0.2, 0.6, 0.9]},
    {"white", [0.9, 0.9, 0.9]},
    {"orange", [1.0, 0.3, 0.1]},
    {"green", [0.3, 0.85, 0.45]}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {id, values} = hd(@presets)

    socket =
      socket
      |> assign(preset: id, map_error: nil)
      |> assign(values)
      |> assign_options()

    {:ok, assign(socket, :uniforms, uniforms(socket.assigns))}
  end

  # Driven from the server: every control changes assigns, and the new
  # uniforms are pushed to the layer.

  @impl true
  def handle_event("preset", %{"preset" => id}, socket) do
    case List.keyfind(@presets, id, 0) do
      {^id, values} ->
        {:noreply, socket |> assign(:preset, id) |> assign(values) |> push_uniforms()}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("color", %{"color" => name}, socket) do
    case List.keyfind(@colors, name, 0) do
      {^name, color} -> {:noreply, socket |> assign(:color, color) |> push_uniforms()}
      nil -> {:noreply, socket}
    end
  end

  def handle_event("options", params, socket) do
    {:noreply,
     socket
     |> assign(
       speed: float(params["speed"]),
       turbulence: float(params["turbulence"]),
       direction: integer(params["direction"]),
       point_size: float(params["point_size"]),
       opacity: float(params["opacity"])
     )
     |> push_uniforms()}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The map's other events arrive too; this scenario does not use them.
  def handle_event(_library_event, _payload, socket), do: {:noreply, socket}

  # The layer's hook listens for "update_uniforms_" followed by its id.
  defp push_uniforms(socket) do
    uniforms = uniforms(socket.assigns)

    socket
    |> assign(:uniforms, uniforms)
    |> assign_options()
    |> push_event("update_uniforms_scenario-particles-layer", %{uniforms: uniforms})
  end

  defp uniforms(assigns) do
    %{
      # Only needs to be present: the browser advances it on every frame.
      "u_time" => 0.0,
      "u_color" => assigns.color,
      "u_speed" => assigns.speed,
      "u_turbulence" => assigns.turbulence,
      "u_flow_direction" => flow(assigns.direction),
      "u_point_size" => assigns.point_size,
      "u_opacity" => assigns.opacity
    }
  end

  # A compass bearing as a direction in Mercator coordinates, where y grows
  # southwards: north is [0, -1], east [1, 0].
  defp flow(degrees) do
    radians = degrees * :math.pi() / 180
    [Float.round(:math.sin(radians), 4), Float.round(-:math.cos(radians), 4)]
  end

  defp vertex_shader, do: @vertex_shader
  defp fragment_shader, do: @fragment_shader
  defp presets, do: Enum.map(@presets, &elem(&1, 0))
  defp colors, do: @colors

  defp css_color([r, g, b]), do: "rgb(#{round(r * 255)}, #{round(g * 255)}, #{round(b * 255)})"

  defp assign_options(socket) do
    form =
      socket.assigns
      |> Map.take([:speed, :turbulence, :direction, :point_size, :opacity])
      |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)
      |> to_form()

    assign(socket, :options, form)
  end

  # Slider values arrive as strings: "2.5", "135".
  defp float(value) do
    case Float.parse(value || "") do
      {float, _rest} -> float
      :error -> 1.0
    end
  end

  defp integer(value) do
    case Integer.parse(value || "") do
      {integer, _rest} -> integer
      :error -> 0
    end
  end
end
