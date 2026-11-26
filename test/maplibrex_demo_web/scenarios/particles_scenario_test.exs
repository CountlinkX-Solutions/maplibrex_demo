defmodule MaplibrexDemoWeb.Scenarios.ParticlesScenarioTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Scenarios.ParticlesScenario

  @layer "#scenario-particles-layer"

  defp mount_scenario(conn) do
    {:ok, view, _html} = live_isolated(conn, ParticlesScenario, session: %{"locale" => "en"})
    view
  end

  defp config(view) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(@layer)
    |> LazyHTML.attribute("data-config")
    |> hd()
    |> Jason.decode!()
  end

  # MaplibreX 0.1 does not re-render a custom layer's uniforms after mount,
  # so the scenario pushes every change to the layer's own event.
  defp pushed_uniforms(view) do
    assert_push_event(view, "update_uniforms_scenario-particles-layer", %{uniforms: uniforms})
    uniforms
  end

  defp set_options(view, options) do
    defaults = %{
      "speed" => "1.0",
      "turbulence" => "0.3",
      "direction" => "90",
      "point_size" => "3.0",
      "opacity" => "0.8"
    }

    view
    |> element("#scenario-particles-options")
    |> render_change(Map.merge(defaults, options))
  end

  defp assert_close([x, y], [ex, ey]) do
    assert_in_delta x, ex, 0.001
    assert_in_delta y, ey, 0.001
  end

  test "draws a custom WebGL layer with its own shaders, next to its map", %{conn: conn} do
    view = mount_scenario(conn)

    assert has_element?(view, ~s(#scenario-particles-map[phx-hook="MapHook"]))
    assert has_element?(view, ~s(#{@layer}[phx-hook="CustomLayerHook"]))

    config = config(view)
    assert config["mapId"] == "scenario-particles-map"
    assert config["vertexShader"] =~ "gl_Position"
    assert config["fragmentShader"] =~ "gl_FragColor"
    assert Map.has_key?(config["uniforms"], "u_time")
  end

  test "a preset sets every uniform at once", %{conn: conn} do
    view = mount_scenario(conn)

    view |> element("#scenario-particles-preset-lava_flow") |> render_click()

    uniforms = pushed_uniforms(view)
    assert uniforms["u_color"] == [1.0, 0.3, 0.1]
    assert uniforms["u_speed"] == 0.5
    assert_close(uniforms["u_flow_direction"], [0.0, -1.0])
    assert has_element?(view, ~s(#scenario-particles-preset-lava_flow[aria-pressed="true"]))
    assert has_element?(view, "#assign-preset", "lava_flow")
  end

  test "an unknown preset is ignored", %{conn: conn} do
    view = mount_scenario(conn)

    render_click(view, "preset", %{"preset" => "plasma"})

    assert has_element?(view, "#assign-preset", "ocean_currents")
  end

  test "a colour button sets u_color", %{conn: conn} do
    view = mount_scenario(conn)

    view |> element("#scenario-particles-color-green") |> render_click()

    assert pushed_uniforms(view)["u_color"] == [0.3, 0.85, 0.45]
  end

  test "the direction is a compass bearing: its labels and the flow agree", %{conn: conn} do
    view = mount_scenario(conn)

    assert has_element?(view, "#scenario-particles-direction-labels", "N")

    # MapLibre's Mercator y grows southwards, so north is -y.
    for {degrees, flow} <- [{"0", [0, -1]}, {"90", [1, 0]}, {"180", [0, 1]}, {"270", [-1, 0]}] do
      set_options(view, %{"direction" => degrees})
      assert_close(pushed_uniforms(view)["u_flow_direction"], flow)
    end

    assert has_element?(view, "#assign-direction", "270°")
  end

  test "the sliders set speed, turbulence, size and opacity", %{conn: conn} do
    view = mount_scenario(conn)

    set_options(view, %{
      "speed" => "2.5",
      "turbulence" => "0.75",
      "point_size" => "6.5",
      "opacity" => "0.4"
    })

    uniforms = pushed_uniforms(view)
    assert uniforms["u_speed"] == 2.5
    assert uniforms["u_turbulence"] == 0.75
    assert uniforms["u_point_size"] == 6.5
    assert uniforms["u_opacity"] == 0.4
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_scenario(conn)

    render_hook(view, "map:error", %{"error" => "Failed to fetch"})

    assert has_element?(view, ~s(#scenario-particles-map-error[role="alert"]), "Failed to fetch")
  end
end
