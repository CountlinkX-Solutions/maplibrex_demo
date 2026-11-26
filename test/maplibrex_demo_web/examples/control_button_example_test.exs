defmodule MaplibrexDemoWeb.Examples.ControlButtonExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.ControlButtonExample

  @button ~s(#example-control-button-tilt[phx-hook="ControlButtonHook"])

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, ControlButtonExample, session: %{"locale" => "en"})

    view
  end

  test "renders a control button with its click binding, not active", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#{@button}[phx-click="tilt"]))
    assert has_element?(view, ~s(#{@button}[data-config*='"active":false']))
    assert has_element?(view, ~s(#example-control-button-tilt-button[title="Tilt the map"]))
    assert has_element?(view, ~s(#example-control-button-map[data-config*='"pitch":0']))
  end

  test "a click on the button tilts the map and makes it active", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "tilt", %{})

    assert has_element?(view, ~s(#{@button}[data-config*='"active":true']))
    assert has_element?(view, ~s(#example-control-button-tilt-button[title="Flatten the map"]))
    assert has_element?(view, ~s(#example-control-button-map[data-config*='"pitch":60']))
    assert has_element?(view, "#assign-tilted", "true")
    assert has_element?(view, "#assign-presses", "1")

    render_click(view, "tilt", %{})

    assert has_element?(view, ~s(#{@button}[data-config*='"active":false']))
    assert has_element?(view, ~s(#example-control-button-map[data-config*='"pitch":0']))
    assert has_element?(view, "#assign-presses", "2")
  end

  test "map:moved keeps the pitch current after the map is tilted by hand", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:moved", %{"pitch" => 45.5, "bearing" => 10})

    assert has_element?(view, "#assign-pitch", "45.5")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "style failed"})

    assert has_element?(view, ~s(#example-control-button-map-error[role="alert"]), "style failed")
  end
end
