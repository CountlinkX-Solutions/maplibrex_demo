defmodule MaplibrexDemoWeb.Examples.FillLayerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.FillLayerExample

  @layer ~s(#example-fill-water[phx-hook="FillLayerHook"])

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, FillLayerExample, session: %{"locale" => "en"})
    view
  end

  defp layer(fragment), do: ~s(#{@layer}[data-config*='#{fragment}'])

  test "fills OpenStreetMap's water polygons from OpenFreeMap's tiles", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-fill-osm[phx-hook="VectorTileSourceHook"][data-config*="tiles.openfreemap.org/planet"])
           )

    assert has_element?(view, layer(~s("sourceLayer":"water")))
    assert has_element?(view, layer(~s("fill-opacity":0.6)))
    assert has_element?(view, layer(~s("fill-outline-color")))
  end

  test "colour, opacity and outline are paint the controls set", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-fill-color-red") |> render_click()

    view
    |> element("#example-fill-options")
    |> render_change(%{"opacity" => "0.3", "outline" => "false"})

    assert has_element?(view, layer(~s("fill-color":"#c92a2a")))
    assert has_element?(view, layer(~s("fill-opacity":0.3)))
    refute has_element?(view, layer("fill-outline-color"))
    assert has_element?(view, "#assign-outline", "false")
  end

  test "the outline is light on the dark basemap", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, layer(~s("fill-outline-color":"#1f2330")))

    render_hook(view, "theme", %{"theme" => "dark"})

    assert has_element?(view, layer(~s("fill-outline-color":"#e8e9f1")))
  end

  test "a clicked polygon comes back with its class", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "layer:feature_clicked", %{
      "layer_id" => "example-fill-water",
      "feature" => %{"properties" => %{"class" => "river"}}
    })

    assert has_element?(view, "#assign-selected", "river")
  end

  test "source:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{"source_id" => "example-fill-osm", "error" => "503"})

    assert has_element?(view, ~s(#example-fill-map-error[role="alert"]), "503")
  end
end
