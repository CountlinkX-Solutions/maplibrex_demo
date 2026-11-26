defmodule MaplibrexDemoWeb.Examples.MarkerExample do
  @moduledoc """
  The example of `<.marker>`: a marker whose colour, scale, dragging and
  popup text follow assigns, whose dropped position comes back with
  `marker:drag_end`, and markers added and removed from the server.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @lisbon [-9.1393, 38.7223]

  @colors [
    {"purple", "#5b3fa6"},
    {"teal", "#0f8b8d"},
    {"orange", "#d9480f"},
    {"red", "#c92a2a"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(home: @lisbon, view_center: @lisbon, lng_lat: @lisbon, pins: [], map_error: nil)
      |> assign(color: "#5b3fa6", scale: 1.0, draggable: true)
      |> assign(popup_text: gettext("Drag me to a new place."))
      |> assign_options()

    {:ok, socket}
  end

  # Driven from the server: these only change assigns, and <.marker> follows.

  @impl true
  def handle_event("color", %{"color" => color}, socket) do
    if Enum.any?(@colors, fn {_name, hex} -> hex == color end) do
      {:noreply, assign(socket, :color, color)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("options", params, socket) do
    %{"scale" => scale, "draggable" => draggable, "popup_text" => text} = params

    {:noreply,
     socket
     |> assign(scale: number(scale), draggable: draggable == "true")
     |> assign_popup_text(String.trim(text))
     |> assign_options()}
  end

  # Markers added and removed from the server: each one is an element in the
  # template, so adding or removing one is a change to a list.

  def handle_event("add_pin", _params, socket) do
    id = "example-marker-pin-#{length(socket.assigns.pins) + 1}"
    pin = %{id: id, lng_lat: socket.assigns.view_center}

    {:noreply, update(socket, :pins, &(&1 ++ [pin]))}
  end

  def handle_event("remove_pin", _params, socket) do
    {:noreply, update(socket, :pins, &Enum.drop(&1, -1))}
  end

  # Events from the map and the marker. While the marker is dragged, MaplibreX
  # sends marker:dragging at most every 50 ms; marker:drag_end always carries
  # the final position, so it is the one to keep.

  def handle_event(
        "marker:drag_end",
        %{"markerId" => "example-marker", "lngLat" => lng_lat},
        socket
      ) do
    {:noreply, assign(socket, :lng_lat, lng_lat)}
  end

  def handle_event("map:moved", %{"center" => center}, socket) do
    {:noreply, assign(socket, :view_center, center)}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # marker:clicked, marker:drag_start, marker:dragging and the other map
  # events arrive too; this example does not use them.
  def handle_event("marker:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  # A popup is created with the marker, so a blank text keeps the last one
  # rather than removing it.
  defp assign_popup_text(socket, ""), do: socket
  defp assign_popup_text(socket, text), do: assign(socket, :popup_text, text)

  defp assign_options(socket) do
    %{scale: scale, draggable: draggable, popup_text: text} = socket.assigns
    form = to_form(%{"scale" => scale, "draggable" => draggable, "popup_text" => text})

    assign(socket, :options, form)
  end

  defp colors, do: @colors

  # Slider values arrive as strings, "1.6"; the marker's scale is a float.
  defp number(value) do
    case Float.parse(value) do
      {float, _rest} -> float
      :error -> 1.0
    end
  end

  defp lng_lat([lng, lat]), do: "#{Float.round(lng / 1, 4)}, #{Float.round(lat / 1, 4)}"
end
