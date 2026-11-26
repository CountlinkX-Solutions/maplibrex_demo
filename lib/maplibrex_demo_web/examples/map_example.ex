defmodule MaplibrexDemoWeb.Examples.MapExample do
  @moduledoc """
  The reference example for `<.map>`: a camera driven from the server,
  commands that run in the browser, and the map's events coming back.

  An example is a LiveView of its own, with its template next to it
  (`map_example.html.heex`). The component page runs it with `live_render/3`
  and shows both files, read at compile time, so the code on the page is the
  code that runs.

  To add the example of another component, copy this module and its template
  to `<component>_example.ex` and `<component>_example.html.heex`, and set
  `example:` on the component in `MaplibrexDemoWeb.Catalogue`.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  alias MaplibreX.Components.Map, as: MapCmd

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @places [
    %{id: "madrid", center: [-3.7038, 40.4168], zoom: 11},
    %{id: "buenos_aires", center: [-58.3816, -34.6037], zoom: 11},
    %{id: "nairobi", center: [36.8219, -1.2921], zoom: 11}
  ]

  @home hd(@places)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(home: @home, last_click: nil, map_error: nil)
      |> assign_camera(center: @home.center, zoom: @home.zoom, pitch: 0, bearing: 0)

    {:ok, socket}
  end

  # Driven from the server: these only change assigns, and <.map> follows.

  @impl true
  def handle_event("go", %{"place" => id}, socket) do
    case Enum.find(@places, &(&1.id == id)) do
      nil -> {:noreply, socket}
      place -> {:noreply, assign_camera(socket, center: place.center, zoom: place.zoom)}
    end
  end

  def handle_event("camera", %{"zoom" => zoom, "pitch" => pitch, "bearing" => bearing}, socket) do
    {:noreply,
     assign_camera(socket, zoom: number(zoom), pitch: number(pitch), bearing: number(bearing))}
  end

  # Events from the map. MaplibreX debounces map:moved by 150 ms, so keeping
  # the camera in the assigns does not flood the socket while panning.

  def handle_event("map:moved", camera, socket) do
    %{"center" => center, "zoom" => zoom, "pitch" => pitch, "bearing" => bearing} = camera

    {:noreply,
     socket
     |> assign(:map_error, nil)
     |> assign_camera(center: center, zoom: zoom, pitch: pitch, bearing: bearing)}
  end

  def handle_event("map:clicked", %{"lngLat" => lng_lat}, socket) do
    {:noreply, assign(socket, :last_click, lng_lat)}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # map:loaded and map:zoom_changed arrive too; this example does not use them.
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  # The camera lives in plain assigns, which <.map> reads, and in a form for
  # the sliders.
  defp assign_camera(socket, camera) do
    socket = assign(socket, camera)

    form =
      to_form(%{
        "zoom" => socket.assigns.zoom,
        "pitch" => socket.assigns.pitch,
        "bearing" => socket.assigns.bearing
      })

    assign(socket, :camera, form)
  end

  defp places do
    names = %{
      "madrid" => gettext("Madrid"),
      "buenos_aires" => gettext("Buenos Aires"),
      "nairobi" => gettext("Nairobi")
    }

    Enum.map(@places, &{&1.id, names[&1.id]})
  end

  # Slider values arrive as strings: "14.5", "45", "-30".
  defp number(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _ -> value |> Float.parse() |> elem(0)
    end
  end

  defp lng_lat(nil), do: "—"
  defp lng_lat([lng, lat]), do: "#{Float.round(lng / 1, 4)}, #{Float.round(lat / 1, 4)}"
end
