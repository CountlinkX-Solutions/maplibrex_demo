defmodule MaplibrexDemoWeb.Examples.GeolocateControlExample do
  @moduledoc """
  The example of `<.geolocate_control>`: a button that asks the browser for
  its position and follows it, with the control's events telling the server
  what happened, including when the browser does not share a position.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       status: "waiting",
       tracking: false,
       location: nil,
       accuracy: nil,
       error: nil,
       map_error: nil
     )}
  end

  # Events from the control. The browser asks the visitor for permission the
  # first time the button is pressed; the answer arrives as one of these.

  @impl true
  def handle_event("geolocate:location_found", %{"coords" => coords}, socket) do
    {:noreply,
     assign(socket,
       status: "found",
       location: [coords["latitude"], coords["longitude"]],
       accuracy: coords["accuracy"],
       error: nil
     )}
  end

  # While tracking, each new position arrives here.
  def handle_event("geolocate:user_location_updated", %{"coords" => coords}, socket) do
    {:noreply, assign(socket, :location, [coords["latitude"], coords["longitude"]])}
  end

  # A refusal (code 1) also ends tracking, without a tracking_stopped event.
  def handle_event("geolocate:location_error", %{"code" => code, "message" => message}, socket) do
    tracking = socket.assigns.tracking and code != 1

    {:noreply,
     assign(socket, status: "error", tracking: tracking, error: %{code: code, message: message})}
  end

  def handle_event("geolocate:tracking_started", _payload, socket) do
    {:noreply, assign(socket, :tracking, true)}
  end

  def handle_event("geolocate:tracking_stopped", _payload, socket) do
    {:noreply, assign(socket, :tracking, false)}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The map's other events arrive too; this example does not use them.
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  # The codes of the browser's GeolocationPositionError.
  defp explain(%{code: 1}) do
    gettext(
      "The browser denied access to your location. Allow location for this page in the browser's site settings, then press the location button again."
    )
  end

  defp explain(%{code: 2}) do
    gettext(
      "The browser could not find your position. Check that location services are on, then press the location button again."
    )
  end

  defp explain(_error) do
    gettext("Finding your position took too long. Press the location button to try again.")
  end

  defp location(nil), do: "—"
  defp location([lat, lng]), do: "#{round4(lat)}, #{round4(lng)}"

  defp accuracy(nil), do: "—"
  defp accuracy(metres), do: "#{round(metres)} m"

  defp round4(number), do: Float.round(number / 1, 4)
end
