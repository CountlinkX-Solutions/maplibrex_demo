defmodule MaplibrexDemoWeb.Examples.RasterDemSourceExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.RasterDemSourceExample

  # The source hook only runs in a browser. These tests drive the LiveView
  # the way the hook would, with the events it sends.

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, RasterDemSourceExample, session: %{"locale" => "en"})

    view
  end

  defp tile_event(loaded?) do
    %{
      "source_id" => "example-dem",
      "data_type" => "source",
      "tile" => %{"coord" => %{"z" => 10, "x" => 1, "y" => 2}, "isSourceLoaded" => loaded?}
    }
  end

  test "renders a DEM source from the public service, drawn by a hillshade layer", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#example-dem-map[phx-hook="MapHook"]))

    assert has_element?(
             view,
             ~s(#example-dem[phx-hook="RasterDEMSourceHook"][data-config*="tiles.mapterhorn.com"])
           )

    assert has_element?(
             view,
             ~s(#example-dem-hillshade[phx-hook="HillshadeLayerHook"][data-config*="\\"sourceId\\":\\"example-dem\\""])
           )
  end

  test "source:added and source:data report the source's progress", %{conn: conn} do
    view = mount_example(conn)
    assert has_element?(view, "#assign-status", "waiting")

    render_hook(view, "source:added", %{"source_id" => "example-dem"})
    assert has_element?(view, "#assign-status", "added")

    render_hook(view, "source:data", tile_event(false))
    assert has_element?(view, "#assign-status", "loading")

    render_hook(view, "source:data", tile_event(true))
    assert has_element?(view, "#assign-status", "loaded")
    assert has_element?(view, "#assign-data_events", "2")
  end

  test "source:error is shown over the map, naming the services", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{
      "source_id" => "example-dem",
      "error" => "Failed to fetch"
    })

    assert has_element?(view, ~s(#example-dem-map-error[role="alert"]), "Failed to fetch")
    assert has_element?(view, "#example-dem-map-error", "tiles.mapterhorn.com")
    assert has_element?(view, "#assign-status", "error")
  end

  test "a place button moves the map", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-dem-place-andes") |> render_click()

    assert has_element?(view, ~s(#example-dem-map[data-config*="-70.01"]))
    assert has_element?(view, ~s(#example-dem-place-andes[aria-pressed="true"]))
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "Style failed"})

    assert has_element?(view, "#example-dem-map-error", "Style failed")
  end

  test "ignores the events it does not use", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "layer:added", %{"layer_id" => "example-dem-hillshade"})
    render_hook(view, "map:loaded", %{})
    render_hook(view, "source:data", %{"source_id" => "example-dem", "data_type" => "metadata"})

    assert has_element?(view, "#assign-status", "waiting")
  end
end
