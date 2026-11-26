defmodule MaplibrexDemoWeb.Examples.GeolocateControlExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.GeolocateControlExample

  @control ~s(#example-geolocate[phx-hook="GeolocateControlHook"])

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, GeolocateControlExample, session: %{"locale" => "en"})

    view
  end

  defp found(view, lat, lng) do
    render_hook(view, "geolocate:location_found", %{
      "coords" => %{"latitude" => lat, "longitude" => lng, "accuracy" => 25.5}
    })
  end

  test "renders a geolocate control that tracks the location", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#{@control}[data-config*='"mapId":"example-geolocate-map"']))
    assert has_element?(view, ~s(#{@control}[data-config*='"trackUserLocation":true']))
    assert has_element?(view, "#example-geolocate-hint")
    refute has_element?(view, "#example-geolocate-error")
    assert has_element?(view, "#assign-status", "waiting")
  end

  test "geolocate:location_found shows where the browser is", %{conn: conn} do
    view = mount_example(conn)

    found(view, 40.41681, -3.70379)

    assert has_element?(view, "#assign-status", "found")
    assert has_element?(view, "#assign-location", "40.4168, -3.7038")
    assert has_element?(view, "#assign-accuracy", "26 m")
  end

  test "tracking events set tracking, and updates move the location", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "geolocate:tracking_started", %{})
    assert has_element?(view, "#assign-tracking", "true")

    render_hook(view, "geolocate:user_location_updated", %{
      "coords" => %{"latitude" => 48.8566, "longitude" => 2.3522}
    })

    assert has_element?(view, "#assign-location", "48.8566, 2.3522")

    render_hook(view, "geolocate:tracking_stopped", %{})
    assert has_element?(view, "#assign-tracking", "false")
  end

  test "a denied permission is explained, with how to recover", %{conn: conn} do
    view = mount_example(conn)

    # The control starts tracking when pressed, before the browser answers,
    # and sends no tracking_stopped when the answer is a refusal.
    render_hook(view, "geolocate:tracking_started", %{})

    render_hook(view, "geolocate:location_error", %{
      "code" => 1,
      "message" => "User denied Geolocation"
    })

    assert has_element?(view, "#assign-status", "error")
    assert has_element?(view, "#assign-tracking", "false")
    assert has_element?(view, ~s(#example-geolocate-error[role="status"]), "denied")
    assert has_element?(view, "#example-geolocate-error", "User denied Geolocation")
    refute has_element?(view, "#example-geolocate-hint")
  end

  test "an unavailable position has its own explanation", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "geolocate:location_error", %{"code" => 2, "message" => "unavailable"})

    assert has_element?(view, "#example-geolocate-error", "could not find")
  end

  test "a location found after an error clears the error", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "geolocate:location_error", %{"code" => 3, "message" => "Timeout"})
    found(view, 1.0, 2.0)

    refute has_element?(view, "#example-geolocate-error")
    assert has_element?(view, "#assign-status", "found")
  end
end
