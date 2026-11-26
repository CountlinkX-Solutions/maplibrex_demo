defmodule MaplibrexDemoWeb.Examples.PopupExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.PopupExample

  @popup ~s(#example-popup[phx-hook="PopupHook"])

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, PopupExample, session: %{"locale" => "en"})
    view
  end

  test "renders a popup next to the map, open at the first place", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#example-popup-map[phx-hook="MapHook"]))
    assert has_element?(view, ~s(#{@popup}[data-config*='"mapId":"example-popup-map"']))
    assert has_element?(view, ~s(#{@popup}[data-config*='"open":true']))
    assert has_element?(view, ~s(#{@popup}[data-config*='"lngLat":[12.4922,41.8902]']))
    assert has_element?(view, "#example-popup-content", "Colosseum")
    assert has_element?(view, "#assign-open", "true")
  end

  test "a place button moves the popup there and opens it", %{conn: conn} do
    view = mount_example(conn)
    view |> element("#example-popup-options") |> render_change(%{"open" => "false"})

    view |> element("#example-popup-place-trevi") |> render_click()

    assert has_element?(view, ~s(#{@popup}[data-config*='"lngLat":[12.4833,41.9009]']))
    assert has_element?(view, ~s(#example-popup-map[data-config*='"center":[12.4833,41.9009]']))
    assert has_element?(view, ~s(#{@popup}[data-config*='"open":true']))
    assert has_element?(view, "#example-popup-content", "Trevi Fountain")
    assert has_element?(view, ~s(#example-popup-place-trevi[aria-pressed="true"]))
    assert has_element?(view, "#assign-place", "trevi")
  end

  test "an unknown place is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "place", %{"place" => "atlantis"})

    assert has_element?(view, "#assign-place", "colosseum")
  end

  test "the open checkbox closes and reopens the popup", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-popup-options") |> render_change(%{"open" => "false"})
    assert has_element?(view, ~s(#{@popup}[data-config*='"open":false']))
    assert has_element?(view, "#assign-open", "false")

    view |> element("#example-popup-options") |> render_change(%{"open" => "true"})
    assert has_element?(view, ~s(#{@popup}[data-config*='"open":true']))
  end

  test "popup:closed and popup:opened from the browser keep open in step", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "popup:closed", %{"popupId" => "example-popup"})
    assert has_element?(view, "#assign-open", "false")
    assert has_element?(view, "#assign-last_event", "popup:closed")
    assert has_element?(view, ~s(#{@popup}[data-config*='"open":false']))

    render_hook(view, "popup:opened", %{"popupId" => "example-popup", "lngLat" => [12.49, 41.89]})
    assert has_element?(view, "#assign-open", "true")
    assert has_element?(view, "#assign-last_event", "popup:opened")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "style failed"})

    assert has_element?(view, ~s(#example-popup-map-error[role="alert"]), "style failed")
  end
end
