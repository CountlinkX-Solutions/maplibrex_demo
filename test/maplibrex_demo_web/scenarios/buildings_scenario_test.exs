defmodule MaplibrexDemoWeb.Scenarios.BuildingsScenarioTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Scenarios.BuildingsScenario

  @layer "#scenario-buildings-layer"

  defp mount_scenario(conn) do
    {:ok, view, _html} = live_isolated(conn, BuildingsScenario, session: %{"locale" => "en"})
    view
  end

  defp layer_config(view) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(@layer)
    |> LazyHTML.attribute("data-config")
    |> hd()
    |> Jason.decode!()
  end

  defp paint(view), do: layer_config(view)["layer"]["paint"]

  defp set_options(view, options) do
    view
    |> element("#scenario-buildings-options")
    |> render_change(Map.merge(%{"height_scale" => "1.0", "opacity" => "0.85"}, options))
  end

  test "extrudes a grid of sample blocks next to a pitched map", %{conn: conn} do
    view = mount_scenario(conn)

    assert has_element?(
             view,
             ~s(#scenario-buildings-map[phx-hook="MapHook"][data-config*="\\"pitch\\":60"])
           )

    assert has_element?(view, ~s(#{@layer}[data-config*="\\"type\\":\\"fill-extrusion\\""]))

    assert has_element?(
             view,
             ~s([phx-hook="NavigationControlHook"][data-config*="scenario-buildings-map"])
           )

    %{"source" => %{"data" => %{"features" => features}}} = layer_config(view)
    assert length(features) == 225
    assert has_element?(view, "#assign-blocks", "225")
  end

  test "says the blocks are a synthetic grid, not real buildings", %{conn: conn} do
    view = mount_scenario(conn)

    assert has_element?(view, "#scenario-buildings-sample-data")
  end

  test "generates the same blocks every time", %{conn: conn} do
    first = conn |> mount_scenario() |> layer_config()
    second = conn |> mount_scenario() |> layer_config()

    assert first["source"]["data"] == second["source"]["data"]
  end

  test "a colour scheme button sets the colour expression", %{conn: conn} do
    view = mount_scenario(conn)
    assert ["interpolate" | _] = paint(view)["fill-extrusion-color"]

    view |> element("#scenario-buildings-scheme-type") |> render_click()
    assert ["match" | _] = paint(view)["fill-extrusion-color"]
    assert has_element?(view, ~s(#scenario-buildings-scheme-type[aria-pressed="true"]))

    view |> element("#scenario-buildings-scheme-uniform") |> render_click()
    assert is_binary(paint(view)["fill-extrusion-color"])
    assert has_element?(view, "#assign-color_scheme", "uniform")
  end

  test "an unknown colour scheme is ignored", %{conn: conn} do
    view = mount_scenario(conn)

    render_click(view, "scheme", %{"scheme" => "rainbow"})

    assert has_element?(view, "#assign-color_scheme", "height")
  end

  test "the sliders set the height scale and the opacity", %{conn: conn} do
    view = mount_scenario(conn)

    set_options(view, %{"height_scale" => "2.5", "opacity" => "0.5"})

    assert paint(view)["fill-extrusion-height"] == ["*", ["get", "height"], 2.5]
    assert paint(view)["fill-extrusion-opacity"] == 0.5
    assert has_element?(view, "#assign-height_scale", "2.5")
  end

  test "a click on a block shows its type and height", %{conn: conn} do
    view = mount_scenario(conn)

    render_hook(view, "layer:feature_clicked", %{
      "layer_id" => "scenario-buildings-layer",
      "feature" => %{"properties" => %{"type" => "office", "height" => 87.4}}
    })

    assert has_element?(view, "#assign-selected", "office, 87 m")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_scenario(conn)

    render_hook(view, "map:error", %{"error" => "Failed to fetch"})

    assert has_element?(view, ~s(#scenario-buildings-map-error[role="alert"]), "Failed to fetch")
  end
end
