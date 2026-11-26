defmodule MaplibrexDemoWeb.Examples.MarkerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.MarkerExample

  # The marker hook only runs in a browser. These tests drive the LiveView the
  # way the hook would and check what reaches each marker's data-config,
  # which is what the hook reads.

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, MarkerExample, session: %{"locale" => "en"})
    view
  end

  defp config(id, fragment), do: ~s(##{id}[data-config*="#{fragment}"])

  test "renders a marker next to its map, linked by map_id", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#example-marker-map[phx-hook="MapHook"]))
    assert has_element?(view, ~s(#example-marker[phx-hook="MarkerHook"]))
    assert has_element?(view, config("example-marker", ~s(\\"mapId\\":\\"example-marker-map\\")))
    assert has_element?(view, config("example-marker", ~s(\\"draggable\\":true)))
    assert has_element?(view, config("example-marker", ~s(\\"popup\\":)))
  end

  test "a colour button sets the marker's color", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-marker-color-teal") |> render_click()

    assert has_element?(view, config("example-marker", ~s(\\"color\\":\\"#0f8b8d\\")))
    assert has_element?(view, ~s(#example-marker-color-teal[aria-pressed="true"]))
    assert has_element?(view, ~s(#example-marker-color-purple[aria-pressed="false"]))
    assert has_element?(view, "#assign-color", "#0f8b8d")
  end

  test "an unknown colour is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "color", %{"color" => "#000000"})

    assert has_element?(view, "#assign-color", "#5b3fa6")
  end

  test "the options set scale, draggable and the popup text", %{conn: conn} do
    view = mount_example(conn)

    view
    |> element("#example-marker-options")
    |> render_change(%{"scale" => "1.6", "draggable" => "false", "popup_text" => "Hello"})

    assert has_element?(view, config("example-marker", ~s(\\"scale\\":1.6)))
    assert has_element?(view, config("example-marker", ~s(\\"draggable\\":false)))
    assert has_element?(view, config("example-marker", ~s(\\"text\\":\\"Hello\\")))
    assert has_element?(view, "#assign-scale", "1.6")
    assert has_element?(view, "#assign-draggable", "false")
  end

  test "a blank popup text keeps the last one", %{conn: conn} do
    view = mount_example(conn)

    view
    |> element("#example-marker-options")
    |> render_change(%{"scale" => "1.0", "draggable" => "true", "popup_text" => "Kept"})

    view
    |> element("#example-marker-options")
    |> render_change(%{"scale" => "1.0", "draggable" => "true", "popup_text" => "  "})

    assert has_element?(view, config("example-marker", ~s(\\"text\\":\\"Kept\\")))
  end

  test "marker:drag_end brings the dropped position back into the assigns", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "marker:drag_end", %{
      "markerId" => "example-marker",
      "lngLat" => [-9.1512, 38.7301]
    })

    assert has_element?(view, config("example-marker", "-9.1512"))
    assert has_element?(view, "#assign-lng_lat", "-9.1512, 38.7301")
  end

  test "markers are added at the map's centre and removed from the server", %{conn: conn} do
    view = mount_example(conn)
    assert has_element?(view, "#example-marker-remove[disabled]")

    render_hook(view, "map:moved", %{
      "center" => [-9.2001, 38.7002],
      "zoom" => 12,
      "pitch" => 0,
      "bearing" => 0
    })

    view |> element("#example-marker-add") |> render_click()
    view |> element("#example-marker-add") |> render_click()

    assert has_element?(view, ~s(#example-marker-pin-1[phx-hook="MarkerHook"]))
    assert has_element?(view, config("example-marker-pin-1", "-9.2001"))
    assert has_element?(view, "#example-marker-pin-2")
    assert has_element?(view, "#assign-pins", "2")

    view |> element("#example-marker-remove") |> render_click()

    assert has_element?(view, "#example-marker-pin-1")
    refute has_element?(view, "#example-marker-pin-2")
    assert has_element?(view, "#assign-pins", "1")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "Failed to fetch"})

    assert has_element?(view, ~s(#example-marker-map-error[role="alert"]), "Failed to fetch")
  end

  test "ignores the events it does not use", %{conn: conn} do
    view = mount_example(conn)

    for event <- ~w(marker:clicked marker:drag_start marker:dragging map:loaded map:clicked) do
      render_hook(view, event, %{"markerId" => "example-marker", "lngLat" => [0, 0]})
    end

    assert has_element?(view, "#assign-lng_lat", "-9.1393, 38.7223")
  end

  test "shows the basemap attribution", %{conn: conn} do
    view = mount_example(conn)

    refute has_element?(
             view,
             config("example-marker-map", ~s(\\"attributionControl\\":false))
           )
  end
end
