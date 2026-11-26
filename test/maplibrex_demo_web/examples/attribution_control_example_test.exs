defmodule MaplibrexDemoWeb.Examples.AttributionControlExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.AttributionControlExample

  @control ~s([phx-hook="AttributionControlHook"])

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, AttributionControlExample, session: %{"locale" => "en"})

    view
  end

  defp control(fragment), do: ~s(#{@control}[data-config*='#{fragment}'])

  test "replaces the map's own attribution with the component", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-attribution-map[data-config*='"attributionControl":false'])
           )

    assert has_element?(view, control(~s("mapId":"example-attribution-map")))
    assert has_element?(view, control(~s("position":"bottom-right")))
    assert has_element?(view, control(~s("compact":false)))
    assert has_element?(view, control(~s("customAttribution":null)))
  end

  test "a position button mounts the control in that corner", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-attribution-position-bottom-left") |> render_click()

    assert has_element?(view, control(~s("position":"bottom-left")))
    refute has_element?(view, control(~s("position":"bottom-right")))
    assert has_element?(view, ~s(#example-attribution-position-bottom-left[aria-pressed="true"]))
    assert has_element?(view, "#assign-position", "bottom-left")
  end

  test "an unknown position is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "position", %{"position" => "middle"})

    assert has_element?(view, "#assign-position", "bottom-right")
  end

  test "the checkboxes set compact and a custom attribution", %{conn: conn} do
    view = mount_example(conn)

    view
    |> element("#example-attribution-options")
    |> render_change(%{"compact" => "true", "custom" => "true"})

    assert has_element?(view, control(~s("compact":true)))
    assert has_element?(view, control(~s("customAttribution":"MaplibreX demo")))
    assert has_element?(view, "#assign-compact", "true")
    assert has_element?(view, "#assign-custom_attribution", "MaplibreX demo")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "style failed"})

    assert has_element?(view, ~s(#example-attribution-map-error[role="alert"]), "style failed")
  end
end
