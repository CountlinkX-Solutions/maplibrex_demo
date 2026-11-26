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

  test "a look button sets the paint, mounting a new layer", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-hillshade-look-warm") |> render_click()

    assert has_element?(view, layer(~s(\\"hillshade-shadow-color\\":\\"#473b24\\")))
    assert has_element?(view, ~s(#example-hillshade-look-warm[aria-pressed="true"]))
    assert has_element?(view, "#example-hillshade-warm")
    refute has_element?(view, "#example-hillshade-plain")
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

  test "layer:added and layer:removed say which layer is on the map", %{conn: conn} do
    view = mount_example(conn)
    assert has_element?(view, "#assign-on_map", "—")

    render_hook(view, "layer:added", %{"layer_id" => "example-hillshade-plain"})
    assert has_element?(view, "#assign-on_map", "example-hillshade-plain")

    render_hook(view, "layer:removed", %{"layer_id" => "example-hillshade-plain"})
    assert has_element?(view, "#assign-on_map", "—")
  end

  test "a new look's layer:added may arrive before the old layer's removal", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "layer:added", %{"layer_id" => "example-hillshade-plain"})
    render_hook(view, "layer:added", %{"layer_id" => "example-hillshade-warm"})
    render_hook(view, "layer:removed", %{"layer_id" => "example-hillshade-plain"})

    assert has_element?(view, "#assign-on_map", "example-hillshade-warm")
  end

  test "source:error and map:error are shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{"source_id" => "example-hillshade-dem", "error" => "404"})

    assert has_element?(view, ~s(#example-hillshade-map-error[role="alert"]), "404")
  end
end
