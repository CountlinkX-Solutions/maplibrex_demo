defmodule MaplibrexDemoWeb.Examples.ControlGroupExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.ControlGroupExample

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, ControlGroupExample, session: %{"locale" => "en"})
    view
  end

  test "renders one group of zoom buttons on the map", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-control-group[phx-hook="ControlGroupHook"][data-config*='"position":"top-left"'])
           )

    for level <- ~w(country city street) do
      assert has_element?(
               view,
               ~s(#example-control-group-content #example-control-group-#{level}[phx-click="zoom"])
             )
    end

    assert has_element?(view, ~s(#example-control-group-city[aria-pressed="true"]))
  end

  test "a button in the group sets the map's zoom", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-control-group-street") |> render_click()

    assert has_element?(view, ~s(#example-control-group-map[data-config*='"zoom":16']))
    assert has_element?(view, ~s(#example-control-group-street[aria-pressed="true"]))
    assert has_element?(view, ~s(#example-control-group-city[aria-pressed="false"]))
    assert has_element?(view, "#assign-zoom", "16")
  end

  test "an unknown level is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "zoom", %{"level" => "orbit"})

    assert has_element?(view, "#assign-zoom", "11")
  end

  test "map:moved keeps the zoom current, so a level can be chosen again", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:moved", %{"zoom" => 12.5})

    assert has_element?(view, "#assign-zoom", "12.5")
    refute has_element?(view, ~s(#example-control-group-content [aria-pressed="true"]))

    view |> element("#example-control-group-city") |> render_click()
    assert has_element?(view, ~s(#example-control-group-map[data-config*='"zoom":11']))
  end
end
