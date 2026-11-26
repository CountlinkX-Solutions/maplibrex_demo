defmodule MaplibrexDemoWeb.Examples.LineLayerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.LineLayerExample

  @layer ~s(#example-line-roads[phx-hook="LineLayerHook"])

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, LineLayerExample, session: %{"locale" => "en"})
    view
  end

  defp layer(fragment), do: ~s(#{@layer}[data-config*='#{fragment}'])

  test "draws OpenStreetMap's main roads from OpenFreeMap's tiles", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-line-osm[phx-hook="VectorTileSourceHook"][data-config*="tiles.openfreemap.org/planet"])
           )

    assert has_element?(view, layer(~s("sourceLayer":"transportation")))
    assert has_element?(view, layer(~s("motorway")))
    assert has_element?(view, layer(~s("line-width":3)))
    assert has_element?(view, layer(~s("line-cap":"round")))
    refute has_element?(view, layer("line-dasharray"))
  end

  test "colour, width and dashes are paint the controls set", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-line-color-orange") |> render_click()

    view
    |> element("#example-line-options")
    |> render_change(%{"width" => "6", "dashed" => "true"})

    assert has_element?(view, layer(~s("line-color":"#d9480f")))
    assert has_element?(view, layer(~s("line-width":6)))
    assert has_element?(view, layer(~s("line-dasharray":[2,1])))

    view
    |> element("#example-line-options")
    |> render_change(%{"width" => "6", "dashed" => "false"})

    refute has_element?(view, layer("line-dasharray"))
    assert has_element?(view, "#assign-dashed", "false")
  end

  test "a clicked road comes back with its class", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "layer:feature_clicked", %{
      "layer_id" => "example-line-roads",
      "feature" => %{"properties" => %{"class" => "primary"}}
    })

    assert has_element?(view, "#assign-selected", "primary")
  end

  test "source:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{"source_id" => "example-line-osm", "error" => "503"})

    assert has_element?(view, ~s(#example-line-map-error[role="alert"]), "503")
  end
end
