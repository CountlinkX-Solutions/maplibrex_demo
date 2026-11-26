defmodule MaplibrexDemoWeb.Examples.NavigationControlExample do
  @moduledoc """
  The example of `<.navigation_control>`: zoom buttons and a compass, in the
  corner and with the parts the assigns choose.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale,
  # copies each map event to the page's Events tab and keeps @theme on the
  # page's light or dark theme.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  # OpenFreeMap's basemap for the page's theme: the map's style follows @theme.
  defp basemap("dark"), do: "https://tiles.openfreemap.org/styles/dark"
  defp basemap("light"), do: "https://tiles.openfreemap.org/styles/liberty"

  @positions ~w(top-left top-right bottom-left bottom-right)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(position: "top-right", map_error: nil)
      |> assign(show_compass: true, show_zoom: true, visualize_pitch: true)
      |> assign_options()

    {:ok, socket}
  end

  @impl true
  def handle_event("position", %{"position" => position}, socket)
      when position in @positions do
    {:noreply, assign(socket, :position, position)}
  end

  def handle_event("position", _params, socket), do: {:noreply, socket}

  def handle_event("options", params, socket) do
    {:noreply,
     socket
     |> assign(
       show_compass: params["show_compass"] == "true",
       show_zoom: params["show_zoom"] == "true",
       visualize_pitch: params["visualize_pitch"] == "true"
     )
     |> assign_options()}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The map's other events arrive too; this example does not use them.
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp assign_options(socket) do
    form =
      to_form(%{
        "show_compass" => socket.assigns.show_compass,
        "show_zoom" => socket.assigns.show_zoom,
        "visualize_pitch" => socket.assigns.visualize_pitch
      })

    assign(socket, :options, form)
  end

  defp positions, do: @positions
end
