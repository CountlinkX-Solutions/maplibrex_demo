defmodule MaplibrexDemoWeb.Examples.RasterTileSourceExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.RasterTileSourceExample

  @source ~s(#example-raster-tiles[phx-hook="RasterTileSourceHook"])

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, RasterTileSourceExample, session: %{"locale" => "en"})

    view
  end

  test "renders NASA imagery tiles as the whole map, credited", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#{@source}[data-config*="gibs.earthdata.nasa.gov"]))
    assert has_element?(view, ~s(#{@source}[data-config*="BlueMarble_ShadedRelief_Bathymetry"]))
    assert has_element?(view, ~s(#{@source}[data-config*="NASA"]))
    assert has_element?(view, ~s(#{@source}[data-config*='"tileSize":256']))

    assert has_element?(
             view,
             ~s(#example-raster-tiles-layer[phx-hook="RasterLayerHook"][data-config*='"sourceId":"example-raster-tiles"'])
           )

    assert has_element?(view, ~s(#example-raster-map[data-config*='"layers":[]']))
  end

  test "an imagery button changes the source's tiles", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-raster-imagery-night") |> render_click()

    assert has_element?(view, ~s(#{@source}[data-config*="VIIRS_CityLights_2012"]))
    refute has_element?(view, ~s(#{@source}[data-config*="BlueMarble"]))
    assert has_element?(view, ~s(#example-raster-imagery-night[aria-pressed="true"]))
    assert has_element?(view, "#assign-imagery", "night")
  end

  test "an unknown imagery is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "imagery", %{"imagery" => "mars"})

    assert has_element?(view, "#assign-imagery", "day")
  end

  test "the source's events report its progress", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:added", %{"source_id" => "example-raster-tiles"})
    assert has_element?(view, "#assign-status", "added")

    render_hook(view, "source:data", %{
      "source_id" => "example-raster-tiles",
      "tile" => %{"coord" => %{"x" => 0, "y" => 0, "z" => 1}, "isSourceLoaded" => true}
    })

    assert has_element?(view, "#assign-status", "loaded")
    assert has_element?(view, "#assign-data_events", "1")
  end

  test "source:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{"source_id" => "example-raster-tiles", "error" => "503"})

    assert has_element?(view, ~s(#example-raster-map-error[role="alert"]), "503")
  end
end
