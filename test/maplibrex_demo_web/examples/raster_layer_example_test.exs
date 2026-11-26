defmodule MaplibrexDemoWeb.Examples.RasterLayerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.RasterLayerExample

  @layer ~s(#example-raster-layer-imagery[phx-hook="RasterLayerHook"])

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, RasterLayerExample, session: %{"locale" => "en"})
    view
  end

  defp layer(fragment), do: ~s(#{@layer}[data-config*='#{fragment}'])

  test "draws NASA imagery over the basemap", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-raster-layer-tiles[phx-hook="RasterTileSourceHook"][data-config*="gibs.earthdata.nasa.gov"])
           )

    assert has_element?(view, layer(~s("sourceId":"example-raster-layer-tiles")))
    assert has_element?(view, layer(~s("raster-opacity":0.7)))
    assert has_element?(view, layer(~s("raster-saturation":0)))
    assert has_element?(view, layer(~s("raster-hue-rotate":0)))
  end

  test "the sliders set opacity, saturation and hue", %{conn: conn} do
    view = mount_example(conn)

    view
    |> element("#example-raster-layer-options")
    |> render_change(%{"opacity" => "0.4", "saturation" => "-1", "hue" => "180"})

    assert has_element?(view, layer(~s("raster-opacity":0.4)))
    assert has_element?(view, layer(~s("raster-saturation":-1.0)))
    assert has_element?(view, layer(~s("raster-hue-rotate":180)))
    assert has_element?(view, "#assign-saturation", "-1.0")
  end

  test "source:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{
      "source_id" => "example-raster-layer-tiles",
      "error" => "503"
    })

    assert has_element?(view, ~s(#example-raster-layer-map-error[role="alert"]), "503")
  end
end
