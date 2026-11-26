defmodule MaplibrexDemoWeb.Examples.ControlExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.ControlExample

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, ControlExample, session: %{"locale" => "en"})
    view
  end

  test "renders the basemap form as a control on the map", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-control-basemaps[phx-hook="ControlHook"][data-config*='"mapId":"example-control-map"'])
           )

    assert has_element?(view, "#example-control-basemaps-content #example-control-basemap-form")
    assert has_element?(view, ~s(#example-control-basemap-liberty[checked]))

    assert has_element?(
             view,
             ~s(#example-control-map[data-config*="tiles.openfreemap.org/styles/liberty"])
           )
  end

  test "choosing a basemap in the control changes the map's style", %{conn: conn} do
    view = mount_example(conn)

    view
    |> element("#example-control-basemap-form")
    |> render_change(%{"basemap" => "positron"})

    assert has_element?(
             view,
             ~s(#example-control-map[data-config*="tiles.openfreemap.org/styles/positron"])
           )

    assert has_element?(view, ~s(#example-control-basemap-positron[checked]))
    refute has_element?(view, ~s(#example-control-basemap-liberty[checked]))
    assert has_element?(view, "#assign-basemap", "positron")
  end

  test "an unknown basemap is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_change(view, "basemap", %{"basemap" => "neon"})

    assert has_element?(view, "#assign-basemap", "liberty")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "style failed"})

    assert has_element?(view, ~s(#example-control-map-error[role="alert"]), "style failed")
  end
end
