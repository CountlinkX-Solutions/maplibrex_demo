defmodule MaplibrexDemoWeb.Examples.FullscreenControlExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.FullscreenControlExample

  @control ~s([phx-hook="FullscreenControlHook"])

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, FullscreenControlExample, session: %{"locale" => "en"})

    view
  end

  defp control(fragment), do: ~s(#{@control}[data-config*="#{fragment}"])

  test "renders one fullscreen control next to its map, linked by map_id", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#example-fullscreen-map[phx-hook="MapHook"]))
    assert has_element?(view, control(~s(\\"mapId\\":\\"example-fullscreen-map\\")))
    assert has_element?(view, control(~s(\\"containerSelector\\":null)))
  end

  test "a container button puts the whole example in full screen", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-fullscreen-container-example") |> render_click()

    assert has_element?(view, control(~s(\\"containerSelector\\":\\"fullscreen-example\\")))
    assert has_element?(view, "#fullscreen-example")
    assert has_element?(view, "#assign-container_id", "fullscreen-example")
  end

  test "a position button moves the control", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-fullscreen-position-bottom-right") |> render_click()

    assert has_element?(view, control(~s(\\"position\\":\\"bottom-right\\")))
    assert has_element?(view, "#assign-position", "bottom-right")
  end

  test "fullscreen:entered and fullscreen:exited keep the state in the assigns", %{conn: conn} do
    view = mount_example(conn)
    assert has_element?(view, "#assign-fullscreen", "false")

    render_hook(view, "fullscreen:entered", %{
      "controlId" => "x",
      "mapId" => "example-fullscreen-map"
    })

    assert has_element?(view, "#assign-fullscreen", "true")

    render_hook(view, "fullscreen:exited", %{
      "controlId" => "x",
      "mapId" => "example-fullscreen-map"
    })

    assert has_element?(view, "#assign-fullscreen", "false")
  end

  test "an unknown container is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "container", %{"container" => "body"})

    assert has_element?(view, control(~s(\\"containerSelector\\":null)))
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "Failed to fetch"})

    assert has_element?(view, ~s(#example-fullscreen-map-error[role="alert"]), "Failed to fetch")
  end
end
