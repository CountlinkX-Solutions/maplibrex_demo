defmodule MaplibrexDemoWeb.Examples.NavigationControlExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.NavigationControlExample

  @control ~s([phx-hook="NavigationControlHook"])

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, NavigationControlExample, session: %{"locale" => "en"})

    view
  end

  defp control(fragment), do: ~s(#{@control}[data-config*="#{fragment}"])

  defp set_options(view, options) do
    view
    |> element("#example-navigation-options")
    |> render_change(
      Map.merge(
        %{"show_compass" => "true", "show_zoom" => "true", "visualize_pitch" => "true"},
        options
      )
    )
  end

  test "renders one navigation control next to its map, linked by map_id", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#example-navigation-map[phx-hook="MapHook"]))
    assert has_element?(view, control(~s(\\"mapId\\":\\"example-navigation-map\\")))
    assert has_element?(view, control(~s(\\"position\\":\\"top-right\\")))
    assert has_element?(view, control(~s(\\"visualizePitch\\":true)))
  end

  test "a position button moves the control to that corner", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-navigation-position-bottom-left") |> render_click()

    assert has_element?(view, control(~s(\\"position\\":\\"bottom-left\\")))
    refute has_element?(view, control(~s(\\"position\\":\\"top-right\\")))
    assert has_element?(view, ~s(#example-navigation-position-bottom-left[aria-pressed="true"]))
    assert has_element?(view, "#assign-position", "bottom-left")
  end

  test "a new option mounts a new control, since options are read at mount", %{conn: conn} do
    view = mount_example(conn)
    [before] = control_ids(view)

    set_options(view, %{"show_compass" => "false"})

    [after_change] = control_ids(view)
    assert after_change != before
    assert has_element?(view, control(~s(\\"showCompass\\":false)))
    assert has_element?(view, "#assign-show_compass", "false")
  end

  test "the options set show_zoom and visualize_pitch", %{conn: conn} do
    view = mount_example(conn)

    set_options(view, %{"show_zoom" => "false", "visualize_pitch" => "false"})

    assert has_element?(view, control(~s(\\"showZoom\\":false)))
    assert has_element?(view, control(~s(\\"visualizePitch\\":false)))
  end

  test "an unknown position is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "position", %{"position" => "middle"})

    assert has_element?(view, "#assign-position", "top-right")
  end

  test "map:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "Failed to fetch"})
    render_hook(view, "map:moved", %{"center" => [0, 0], "zoom" => 3})

    assert has_element?(view, ~s(#example-navigation-map-error[role="alert"]), "Failed to fetch")
  end

  defp control_ids(view) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(@control)
    |> LazyHTML.attribute("id")
  end
end
