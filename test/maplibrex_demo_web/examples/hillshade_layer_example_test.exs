defmodule MaplibrexDemoWeb.Examples.HillshadeLayerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.HillshadeLayerExample

  @layer ~s([phx-hook="HillshadeLayerHook"])

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, HillshadeLayerExample, session: %{"locale" => "en"})

    view
  end

  defp layer(fragment), do: ~s(#{@layer}[data-config*="#{fragment}"])

  test "renders a hillshade layer over its DEM source, next to the map", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#example-hillshade-map[phx-hook="MapHook"]))

    assert has_element?(
             view,
             ~s(#example-hillshade-dem[phx-hook="RasterDEMSourceHook"][data-config*="tiles.mapterhorn.com"])
           )

    assert has_element?(view, layer(~s(\\"sourceId\\":\\"example-hillshade-dem\\")))
    assert has_element?(view, layer(~s(\\"mapId\\":\\"example-hillshade-map\\")))
  end

  test "a look button repaints the same layer", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-hillshade-look-warm") |> render_click()

    assert has_element?(
             view,
             ~s(#example-hillshade-layer#{@layer}[data-config*="#473b24"])
           )

    assert has_element?(view, ~s(#example-hillshade-look-warm[aria-pressed="true"]))
    assert has_element?(view, "#assign-look", "warm")
  end

  test "an unknown look is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "look", %{"look" => "neon"})

    assert has_element?(view, "#assign-look", "plain")
  end

  test "the visible checkbox removes and brings back the layer with :if", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-hillshade-options") |> render_change(%{"visible" => "false"})

    refute has_element?(view, @layer)
    assert has_element?(view, "#example-hillshade-dem")
    assert has_element?(view, "#assign-visible", "false")

    view |> element("#example-hillshade-options") |> render_change(%{"visible" => "true"})

    assert has_element?(view, @layer)
  end

  test "layer:added and layer:removed say whether the layer is on the map", %{conn: conn} do
    view = mount_example(conn)
    assert has_element?(view, "#assign-on_map", "false")

    render_hook(view, "layer:added", %{"layer_id" => "example-hillshade-layer"})
    assert has_element?(view, "#assign-on_map", "true")

    render_hook(view, "layer:removed", %{"layer_id" => "example-hillshade-layer"})
    assert has_element?(view, "#assign-on_map", "false")
  end

  test "source:error and map:error are shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{"source_id" => "example-hillshade-dem", "error" => "404"})

    assert has_element?(view, ~s(#example-hillshade-map-error[role="alert"]), "404")
  end
end
