defmodule MaplibrexDemoWeb.Examples.ZoomRangeExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.ZoomRangeExample

  @range ~s([phx-hook="ZoomRangeHook"])

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, ZoomRangeExample, session: %{"locale" => "en"})
    view
  end

  defp range(fragment), do: ~s(#{@range}[data-config*='#{fragment}'])

  test "renders content shown from zoom 12, over the map", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, range(~s("mapId":"example-zoom-range-map")))
    assert has_element?(view, range(~s("min":12)))
    assert has_element?(view, range(~s("max":null)))
    assert has_element?(view, "#example-zoom-range-badge", "12")
    assert has_element?(view, "#assign-shown", "false")
  end

  test "a range button mounts the content with that range", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-zoom-range-preset-between") |> render_click()

    assert has_element?(view, range(~s("min":8)))
    assert has_element?(view, range(~s("max":12)))
    refute has_element?(view, range(~s("min":12)))
    assert has_element?(view, ~s(#example-zoom-range-preset-between[aria-pressed="true"]))
    assert has_element?(view, "#assign-min", "8")
    assert has_element?(view, "#assign-max", "12")
    assert has_element?(view, "#assign-shown", "true")
  end

  test "an unknown range is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "range", %{"range" => "everywhere"})

    assert has_element?(view, "#assign-min", "12")
  end

  test "map:moved keeps the zoom, and whether the content is shown, current", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:moved", %{"zoom" => 13.25})

    assert has_element?(view, "#assign-zoom", "13.25")
    assert has_element?(view, "#assign-shown", "true")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "style failed"})

    assert has_element?(view, ~s(#example-zoom-range-map-error[role="alert"]), "style failed")
  end
end
