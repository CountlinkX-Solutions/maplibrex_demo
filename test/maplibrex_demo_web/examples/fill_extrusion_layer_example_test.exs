defmodule MaplibrexDemoWeb.Examples.FillExtrusionLayerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.FillExtrusionLayerExample

  @layer ~s(#example-extrusion-buildings[phx-hook="FillExtrusionLayerHook"])

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, FillExtrusionLayerExample, session: %{"locale" => "en"})

    view
  end

  defp layer(fragment), do: ~s(#{@layer}[data-config*='#{fragment}'])

  test "extrudes OpenStreetMap's buildings to their height", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-extrusion-osm[phx-hook="VectorTileSourceHook"][data-config*="tiles.openfreemap.org/planet"])
           )

    assert has_element?(view, layer(~s("sourceLayer":"building")))

    assert has_element?(
             view,
             layer(~s("fill-extrusion-height":["*",["get","render_height"],1.0]))
           )

    assert has_element?(view, ~s(#example-extrusion-map[data-config*='"pitch":55']))
  end

  test "the height slider and colour buttons set the paint", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-extrusion-options") |> render_change(%{"scale" => "2.5"})
    view |> element("#example-extrusion-color-orange") |> render_click()

    assert has_element?(
             view,
             layer(~s("fill-extrusion-height":["*",["get","render_height"],2.5]))
           )

    assert has_element?(view, layer(~s("fill-extrusion-color":"#d9480f")))
    assert has_element?(view, "#assign-scale", "2.5")
  end

  test "a clicked building comes back with its height", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "layer:feature_clicked", %{
      "layer_id" => "example-extrusion-buildings",
      "features" => [%{"properties" => %{"render_height" => 259}}],
      "lngLat" => %{"lng" => -73.98, "lat" => 40.75}
    })

    assert has_element?(view, "#assign-selected", "259 m")
  end

  test "source:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{"source_id" => "example-extrusion-osm", "error" => "503"})

    assert has_element?(view, ~s(#example-extrusion-map-error[role="alert"]), "503")
  end
end
