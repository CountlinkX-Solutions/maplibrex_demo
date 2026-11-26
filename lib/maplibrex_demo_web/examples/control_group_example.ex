defmodule MaplibrexDemoWeb.Examples.ControlGroupExample do
  @moduledoc """
  The example of `<.control_group>`: three buttons shown as one map
  control, each setting the map's zoom from the server.
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

  @levels [
    %{id: "country", zoom: 5, icon: "hero-globe-americas"},
    %{id: "city", zoom: 11, icon: "hero-building-office-2"},
    %{id: "street", zoom: 16, icon: "hero-map-pin"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, zoom: 11, map_error: nil)}
  end

  # From the buttons in the group.
  @impl true
  def handle_event("zoom", %{"level" => id}, socket) do
    case Enum.find(@levels, &(&1.id == id)) do
      nil -> {:noreply, socket}
      level -> {:noreply, assign(socket, :zoom, level.zoom)}
    end
  end

  # The visitor can zoom the map too; map:moved keeps the zoom assign in
  # step, so a button always has a new zoom to set.
  def handle_event("map:moved", %{"zoom" => zoom}, socket) do
    {:noreply, assign(socket, :zoom, zoom)}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The map's other events arrive too; this example does not use them.
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp levels, do: @levels

  defp label("country"), do: gettext("Zoom to the country")
  defp label("city"), do: gettext("Zoom to the city")
  defp label("street"), do: gettext("Zoom to street level")
end
