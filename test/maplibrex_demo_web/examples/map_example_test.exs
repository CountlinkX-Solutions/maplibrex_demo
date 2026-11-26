defmodule MaplibrexDemoWeb.Examples.MapExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.MapExample

  # The map itself only exists in a browser. These tests drive the LiveView
  # the way the map hook would, and check the assigns reach the map's
  # data-config, which is what the hook reads.

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, MapExample, session: %{"locale" => "en"})
    view
  end

  defp moved(view, payload) do
    render_hook(
      view,
      "map:moved",
      Map.merge(
        %{"center" => [-3.7, 40.42], "zoom" => 11, "pitch" => 0, "bearing" => 0},
        payload
      )
    )
  end

  test "renders a map hooked to MaplibreX with the server's camera", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#example-map[phx-hook="MapHook"][phx-update="ignore"]))
    assert has_element?(view, ~s(#example-map[data-config*="\\"zoom\\":11"]))
  end

  test "a place button moves the map by changing assigns", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-place-nairobi") |> render_click()

    assert has_element?(view, ~s(#example-map[data-config*="36.8219"]))
    assert has_element?(view, "#assign-center", "36.8219")
  end

  describe "markers nested in <.map>" do
    defp marker(id), do: ~s(#example-map-place-#{id}[phx-hook="MarkerHook"])

    test "are rendered after the map element, one per place", %{conn: conn} do
      view = mount_example(conn)

      for id <- ~w(madrid buenos_aires nairobi) do
        assert has_element?(view, "#example-map ~ #{marker(id)}")
        assert has_element?(view, ~s(#{marker(id)}[data-config*='"mapId":"example-map"']))
      end

      refute has_element?(view, "#example-map #{marker("madrid")}")
    end

    test "follow the assigns: the chosen place's marker takes the accent", %{conn: conn} do
      view = mount_example(conn)

      assert has_element?(view, ~s(#{marker("madrid")}[data-config*='"color":"#5b3fa6"']))
      assert has_element?(view, ~s(#{marker("nairobi")}[data-config*='"color":"#63637a"']))

      view |> element("#example-place-nairobi") |> render_click()

      assert has_element?(view, ~s(#{marker("nairobi")}[data-config*='"color":"#5b3fa6"']))
      assert has_element?(view, ~s(#{marker("madrid")}[data-config*='"color":"#63637a"']))
      assert has_element?(view, "#assign-place", "nairobi")
      assert has_element?(view, ~s(#example-place-nairobi[aria-pressed="true"]))
    end

    test "mount and unmount with :if", %{conn: conn} do
      view = mount_example(conn)

      view |> element("#example-markers") |> render_change(%{"markers" => "false"})

      refute has_element?(view, ~s([phx-hook="MarkerHook"]))
      assert has_element?(view, "#assign-markers", "false")

      view |> element("#example-markers") |> render_change(%{"markers" => "true"})

      assert has_element?(view, marker("buenos_aires"))
    end
  end

  test "the camera sliders set zoom, pitch and bearing", %{conn: conn} do
    view = mount_example(conn)

    view
    |> element("#example-camera")
    |> render_change(%{"zoom" => "14.5", "pitch" => "45", "bearing" => "-30"})

    assert has_element?(view, ~s(#example-map[data-config*="\\"zoom\\":14.5"]))
    assert has_element?(view, ~s(#example-map[data-config*="\\"pitch\\":45"]))
    assert has_element?(view, ~s(#example-map[data-config*="\\"bearing\\":-30"]))
  end

  test "the commands run in the browser through JS.dispatch", %{conn: conn} do
    view = mount_example(conn)

    for {id, event} <- [
          {"example-zoom-in", "maplibrex:zoom_in"},
          {"example-zoom-out", "maplibrex:zoom_out"},
          {"example-reset-north", "maplibrex:reset_north"},
          {"example-fly-home", "maplibrex:fly_to"}
        ] do
      assert has_element?(view, ~s(##{id}[phx-click*="#{event}"]))
    end
  end

  test "map:moved brings the camera back into the assigns", %{conn: conn} do
    view = mount_example(conn)

    moved(view, %{"zoom" => 7.25, "bearing" => 12.5})

    assert has_element?(view, "#assign-zoom", "7.25")
    assert has_element?(view, "#assign-bearing", "12.5")
  end

  test "map:clicked shows where the map was clicked", %{conn: conn} do
    view = mount_example(conn)
    refute has_element?(view, "#assign-last_click", "2.17")

    render_hook(view, "map:clicked", %{"lngLat" => [2.1734, 41.3851], "point" => [10, 20]})

    assert has_element?(view, "#assign-last_click", "2.1734")
  end

  test "map:error is shown over the map until the map moves again", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:error", %{"error" => "Failed to fetch"})
    assert has_element?(view, ~s(#example-map-error[role="alert"]), "Failed to fetch")

    moved(view, %{})
    refute has_element?(view, "#example-map-error")
  end

  test "ignores the map events it does not use", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:loaded", %{"mapId" => "example-map"})
    render_hook(view, "map:zoom_changed", %{"zoom" => 3})

    assert has_element?(view, "#example-map")
  end

  test "shows the basemap attribution", %{conn: conn} do
    view = mount_example(conn)

    refute has_element?(view, ~s(#example-map[data-config*="\\"attributionControl\\":false"]))
  end
end
