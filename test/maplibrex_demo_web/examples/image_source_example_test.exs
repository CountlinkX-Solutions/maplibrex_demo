defmodule MaplibrexDemoWeb.Examples.ImageSourceExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.ImageSourceExample

  @source ~s(#example-image-radar[phx-hook="ImageSourceHook"])

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, ImageSourceExample, session: %{"locale" => "en"})
    view
  end

  test "renders the first radar image at its four corners, drawn by a raster layer", %{
    conn: conn
  } do
    view = mount_example(conn)

    assert has_element?(view, ~s(#{@source}[data-config*="docs/assets/radar0.gif"]))
    assert has_element?(view, ~s(#{@source}[data-config*="[-80.425,46.437]"]))

    assert has_element?(
             view,
             ~s(#example-image-layer[phx-hook="RasterLayerHook"][data-config*='"sourceId":"example-image-radar"'])
           )

    assert has_element?(view, ~s(#example-image-layer[data-config*='"raster-opacity":0.8']))
    assert has_element?(view, "#example-image-sample-data")
  end

  test "a frame button changes the image's url", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-image-frame-3") |> render_click()

    assert has_element?(view, ~s(#{@source}[data-config*="radar3.gif"]))
    assert has_element?(view, ~s(#example-image-frame-3[aria-pressed="true"]))
    assert has_element?(view, "#assign-frame", "3")
  end

  test "an unknown frame is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "frame", %{"frame" => "9"})

    assert has_element?(view, "#assign-frame", "0")
  end

  test "the opacity slider repaints the layer", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-image-options") |> render_change(%{"opacity" => "0.35"})

    assert has_element?(view, ~s(#example-image-layer[data-config*='"raster-opacity":0.35']))
    assert has_element?(view, "#assign-opacity", "0.35")
  end

  test "playing advances a frame on every tick, and pausing stops it", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-image-play") |> render_click()
    assert has_element?(view, ~s(#example-image-play[aria-pressed="true"]))

    send(view.pid, :tick)
    assert has_element?(view, "#assign-frame", "1")

    view |> element("#example-image-play") |> render_click()
    send(view.pid, :tick)
    assert has_element?(view, "#assign-frame", "1")
    assert has_element?(view, "#assign-playing", "false")
  end

  test "the last frame is followed by the first", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-image-frame-4") |> render_click()
    view |> element("#example-image-play") |> render_click()
    send(view.pid, :tick)

    assert has_element?(view, "#assign-frame", "0")
  end

  test "source:added and source:error report the image", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:added", %{"source_id" => "example-image-radar"})
    assert has_element?(view, "#assign-status", "added")

    render_hook(view, "source:error", %{"source_id" => "example-image-radar", "error" => "404"})
    assert has_element?(view, ~s(#example-image-map-error[role="alert"]), "404")
  end
end
