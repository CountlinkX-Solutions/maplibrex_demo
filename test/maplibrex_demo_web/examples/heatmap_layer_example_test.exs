defmodule MaplibrexDemoWeb.Examples.HeatmapLayerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.HeatmapLayerExample

  @layer ~s(#example-heatmap-layer[phx-hook="HeatmapLayerHook"])

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, HeatmapLayerExample, session: %{"locale" => "en"})
    view
  end

  defp layer(fragment), do: ~s(#{@layer}[data-config*='#{fragment}'])

  test "shows the density of OpenStreetMap's points of interest", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-heatmap-osm[phx-hook="VectorTileSourceHook"][data-config*="tiles.openfreemap.org/planet"])
           )

    assert has_element?(view, layer(~s("sourceLayer":"poi")))
    assert has_element?(view, layer(~s("heatmap-radius":10)))
    assert has_element?(view, layer(~s("heatmap-intensity":0.3)))
  end

  test "the sliders set the radius and intensity paint", %{conn: conn} do
    view = mount_example(conn)

    view
    |> element("#example-heatmap-options")
    |> render_change(%{"radius" => "35", "intensity" => "1.5"})

    assert has_element?(view, layer(~s("heatmap-radius":35)))
    assert has_element?(view, layer(~s("heatmap-intensity":1.5)))
    assert has_element?(view, "#assign-radius", "35")
    assert has_element?(view, "#assign-intensity", "1.5")
  end

  test "layer:added says the heatmap is on the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "layer:added", %{"layer_id" => "example-heatmap-layer"})

    assert has_element?(view, "#assign-on_map", "true")
  end

  test "source:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{"source_id" => "example-heatmap-osm", "error" => "503"})

    assert has_element?(view, ~s(#example-heatmap-map-error[role="alert"]), "503")
  end
end
