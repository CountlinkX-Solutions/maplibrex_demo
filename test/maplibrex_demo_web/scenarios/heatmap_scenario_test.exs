defmodule MaplibrexDemoWeb.Scenarios.HeatmapScenarioTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Scenarios.HeatmapScenario

  @layer "#scenario-heatmap-layer"

  defp mount_scenario(conn) do
    {:ok, view, _html} = live_isolated(conn, HeatmapScenario, session: %{"locale" => "en"})
    view
  end

  defp layer(fragment), do: ~s(#{@layer}[data-config*="#{fragment}"])

  defp layer_config(view) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(@layer)
    |> LazyHTML.attribute("data-config")
    |> hd()
    |> Jason.decode!()
  end

  defp set_options(view, options) do
    view
    |> element("#scenario-heatmap-options")
    |> render_change(
      Map.merge(%{"radius" => "25", "intensity" => "1.0", "opacity" => "0.8"}, options)
    )
  end

  test "draws sample points as a heatmap layer next to its map", %{conn: conn} do
    view = mount_scenario(conn)

    assert has_element?(view, ~s(#scenario-heatmap-map[phx-hook="MapHook"]))
    assert has_element?(view, layer(~s(\\"type\\":\\"heatmap\\")))

    assert has_element?(
             view,
             ~s([phx-hook="NavigationControlHook"][data-config*="scenario-heatmap-map"])
           )

    %{"source" => %{"data" => %{"features" => features}}} = layer_config(view)
    assert length(features) == 500
    assert has_element?(view, "#assign-points", "500")
  end

  test "labels its points as sample data", %{conn: conn} do
    view = mount_scenario(conn)

    assert has_element?(view, "#scenario-heatmap-sample-data")
  end

  test "generates the same sample points every time", %{conn: conn} do
    first = conn |> mount_scenario() |> layer_config()
    second = conn |> mount_scenario() |> layer_config()

    assert first["source"]["data"] == second["source"]["data"]
  end

  test "the sliders set the radius, intensity and opacity paint", %{conn: conn} do
    view = mount_scenario(conn)

    set_options(view, %{"radius" => "40", "intensity" => "2.5", "opacity" => "0.5"})

    %{"layer" => %{"paint" => paint}} = layer_config(view)
    assert paint["heatmap-opacity"] == 0.5
    assert List.last(paint["heatmap-radius"]) == 40
    assert List.last(paint["heatmap-intensity"]) == 7.5
    assert has_element?(view, "#assign-radius", "40")
    assert has_element?(view, "#assign-intensity", "2.5")
    assert has_element?(view, "#assign-opacity", "0.5")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_scenario(conn)

    render_hook(view, "map:error", %{"error" => "Failed to fetch"})

    assert has_element?(view, ~s(#scenario-heatmap-map-error[role="alert"]), "Failed to fetch")
  end

  test "ignores the layer and map events it does not use", %{conn: conn} do
    view = mount_scenario(conn)

    render_hook(view, "layer:source_loaded", %{"layer_id" => "scenario-heatmap-layer"})
    render_hook(view, "map:moved", %{"center" => [0, 0], "zoom" => 3})

    assert has_element?(view, "#assign-radius", "25")
  end
end
