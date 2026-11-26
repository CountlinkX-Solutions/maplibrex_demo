defmodule MaplibrexDemoWeb.Examples.ScaleControlExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.ScaleControlExample

  @control ~s([phx-hook="ScaleControlHook"])

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, ScaleControlExample, session: %{"locale" => "en"})
    view
  end

  defp control(fragment), do: ~s(#{@control}[data-config*="#{fragment}"])

  defp set_options(view, options) do
    view
    |> element("#example-scale-options")
    |> render_change(Map.merge(%{"max_width" => "120", "zoom" => "11"}, options))
  end

  test "renders one scale control next to its map, linked by map_id", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#example-scale-map[phx-hook="MapHook"]))
    assert has_element?(view, control(~s(\\"mapId\\":\\"example-scale-map\\")))
    assert has_element?(view, control(~s(\\"unit\\":\\"metric\\")))
    assert has_element?(view, control(~s(\\"position\\":\\"bottom-left\\")))
  end

  test "a unit button sets the unit and mounts a new control", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-scale-unit-imperial") |> render_click()

    assert has_element?(view, control(~s(\\"unit\\":\\"imperial\\")))
    refute has_element?(view, control(~s(\\"unit\\":\\"metric\\")))
    assert has_element?(view, ~s(#example-scale-unit-imperial[aria-pressed="true"]))
    assert has_element?(view, "#assign-unit", "imperial")
  end

  test "a position button moves the control", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-scale-position-top-right") |> render_click()

    assert has_element?(view, control(~s(\\"position\\":\\"top-right\\")))
  end

  test "the sliders set max_width and the map's zoom", %{conn: conn} do
    view = mount_example(conn)

    set_options(view, %{"max_width" => "200", "zoom" => "6.5"})

    assert has_element?(view, control(~s(\\"maxWidth\\":200)))
    assert has_element?(view, ~s(#example-scale-map[data-config*="\\"zoom\\":6.5"]))
    assert has_element?(view, "#assign-max_width", "200")
  end

  test "map:moved brings the zoom back into the assigns", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:moved", %{"center" => [-0.12, 51.5], "zoom" => 8.25})

    assert has_element?(view, "#assign-zoom", "8.25")
  end

  test "an unknown unit is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "unit", %{"unit" => "furlongs"})

    assert has_element?(view, "#assign-unit", "metric")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "Failed to fetch"})

    assert has_element?(view, ~s(#example-scale-map-error[role="alert"]), "Failed to fetch")
  end
end
