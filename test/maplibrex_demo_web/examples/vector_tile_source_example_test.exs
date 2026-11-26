defmodule MaplibrexDemoWeb.Examples.VectorTileSourceExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.VectorTileSourceExample

  @source ~s(#example-vector-countries[phx-hook="VectorTileSourceHook"])

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, VectorTileSourceExample, session: %{"locale" => "en"})

    view
  end

  test "renders MapLibre's demo tiles and two layers drawing them", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#{@source}[data-config*="demotiles.maplibre.org/tiles/{z}/{x}/{y}.pbf"])
           )

    assert has_element?(view, ~s(#{@source}[data-config*="Natural Earth"]))

    for layer <- ~w(example-vector-fill example-vector-borders) do
      assert has_element?(
               view,
               ~s(##{layer}[data-config*='"sourceId":"example-vector-countries"'][data-config*='"sourceLayer":"countries"'])
             )
    end

    assert has_element?(view, ~s(#example-vector-fill[data-config*='"Europe"']))
  end

  test "a continent button highlights it through the fill's paint", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-vector-continent-africa") |> render_click()

    assert has_element?(view, ~s(#example-vector-fill[data-config*='"Africa"']))
    refute has_element?(view, ~s(#example-vector-fill[data-config*='"Europe"']))
    assert has_element?(view, ~s(#example-vector-continent-africa[aria-pressed="true"]))
    assert has_element?(view, "#assign-continent", "Africa")
  end

  test "an unknown continent is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "continent", %{"continent" => "atlantis"})

    assert has_element?(view, "#assign-continent", "Europe")
  end

  test "the checkbox removes the source with its layers, and brings them back", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-vector-options") |> render_change(%{"enabled" => "false"})

    refute has_element?(view, @source)
    refute has_element?(view, "#example-vector-fill")
    refute has_element?(view, "#example-vector-borders")
    assert has_element?(view, "#assign-enabled", "false")

    view |> element("#example-vector-options") |> render_change(%{"enabled" => "true"})

    assert has_element?(view, @source)
    assert has_element?(view, "#example-vector-fill")
  end

  test "the source's events report its progress", %{conn: conn} do
    view = mount_example(conn)
    assert has_element?(view, "#assign-status", "waiting")

    render_hook(view, "source:added", %{"source_id" => "example-vector-countries"})
    assert has_element?(view, "#assign-status", "added")

    tile = %{"coord" => %{"x" => 0, "y" => 0, "z" => 1}, "isSourceLoaded" => false}
    render_hook(view, "source:data", %{"source_id" => "example-vector-countries", "tile" => tile})
    assert has_element?(view, "#assign-status", "loading")
    assert has_element?(view, "#assign-data_events", "1")

    render_hook(view, "source:data", %{
      "source_id" => "example-vector-countries",
      "tile" => %{tile | "isSourceLoaded" => true}
    })

    assert has_element?(view, "#assign-status", "loaded")

    render_hook(view, "source:removed", %{"source_id" => "example-vector-countries"})
    assert has_element?(view, "#assign-status", "removed")
  end

  test "source:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{
      "source_id" => "example-vector-countries",
      "error" => "404"
    })

    assert has_element?(view, ~s(#example-vector-map-error[role="alert"]), "404")
  end
end
