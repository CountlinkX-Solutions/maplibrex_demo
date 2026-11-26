defmodule MaplibrexDemoWeb.Examples.GeojsonLayerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.GeojsonLayerExample

  # The layer hook only runs in a browser. These tests drive the LiveView the
  # way the hook would and check what reaches the layer's data-config.

  @layer "example-geojson-points"

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, GeojsonLayerExample, session: %{"locale" => "en"})
    view
  end

  defp config(fragment), do: ~s(##{@layer}[data-config*="#{fragment}"])

  defp set_options(view, options) do
    view
    |> element("#example-geojson-options")
    |> render_change(Map.merge(%{"radius" => "8", "visible" => "true"}, options))
  end

  test "renders a circle layer next to its map, linked by map_id", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#example-geojson-map[phx-hook="MapHook"]))
    assert has_element?(view, ~s(##{@layer}[phx-hook="GeoJSONLayerHook"]))
    assert has_element?(view, config(~s(\\"mapId\\":\\"example-geojson-map\\")))
    assert has_element?(view, config(~s(\\"type\\":\\"circle\\")))
    assert has_element?(view, config(~s(\\"circle-radius\\":8)))
  end

  test "labels its points as sample data", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, "#example-geojson-sample-data")
  end

  test "a colour button sets the circle-color paint property", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-geojson-color-orange") |> render_click()

    assert has_element?(view, config(~s(\\"circle-color\\":\\"#d9480f\\")))
    assert has_element?(view, ~s(#example-geojson-color-orange[aria-pressed="true"]))
    assert has_element?(view, "#assign-color", "#d9480f")
  end

  test "the radius slider sets the circle-radius paint property", %{conn: conn} do
    view = mount_example(conn)

    set_options(view, %{"radius" => "14"})

    assert has_element?(view, config(~s(\\"circle-radius\\":14)))
    assert has_element?(view, "#assign-radius", "14")
  end

  test "the visible checkbox removes and brings back the layer with :if", %{conn: conn} do
    view = mount_example(conn)

    set_options(view, %{"visible" => "false"})

    refute has_element?(view, "##{@layer}")
    assert has_element?(view, "#assign-visible", "false")

    set_options(view, %{"visible" => "true"})

    assert has_element?(view, "##{@layer}")
  end

  test "layer:feature_clicked shows the clicked point", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "layer:feature_clicked", %{
      "layer_id" => @layer,
      "feature" => %{"properties" => %{"name" => "Point 3"}},
      "lngLat" => [-3.7, 40.42],
      "point" => [10, 20]
    })

    assert has_element?(view, "#assign-selected", "Point 3")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "Failed to fetch"})

    assert has_element?(view, ~s(#example-geojson-map-error[role="alert"]), "Failed to fetch")
  end

  test "ignores the events it does not use", %{conn: conn} do
    view = mount_example(conn)

    for event <-
          ~w(layer:feature_mouseenter layer:feature_mouseleave layer:source_loaded map:loaded) do
      render_hook(view, event, %{"layer_id" => @layer})
    end

    assert has_element?(view, "#assign-selected", "—")
  end
end
