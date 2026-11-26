defmodule MaplibrexDemoWeb.Examples.ZoomRangeExample do
  @moduledoc """
  The example of `<.zoom_range>`: a note over the map that MaplibreX shows
  only while the zoom is within the range the assigns set. The server
  follows the zoom with `map:moved`, so it knows whether the note is shown.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  alias MaplibreX.Components.Map, as: MapCmd

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @ranges [
    %{id: "from", min: 12, max: nil},
    %{id: "between", min: 8, max: 12},
    %{id: "up_to", min: nil, max: 8}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, range: hd(@ranges), zoom: 10, map_error: nil)}
  end

  @impl true
  def handle_event("range", %{"range" => id}, socket) do
    case Enum.find(@ranges, &(&1.id == id)) do
      nil -> {:noreply, socket}
      range -> {:noreply, assign(socket, :range, range)}
    end
  end

  def handle_event("map:moved", %{"zoom" => zoom}, socket) do
    {:noreply, assign(socket, :zoom, zoom)}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The map's other events arrive too; this example does not use them.
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp ranges, do: @ranges

  # The same test the zoom_range hook makes in the browser.
  defp shown?(%{min: min, max: max}, zoom) do
    (is_nil(min) or zoom >= min) and (is_nil(max) or zoom <= max)
  end

  defp describe(%{min: min, max: nil}), do: gettext("Shown from zoom %{min}", min: min)
  defp describe(%{min: nil, max: max}), do: gettext("Shown up to zoom %{max}", max: max)

  defp describe(%{min: min, max: max}),
    do: gettext("Shown between zoom %{min} and %{max}", min: min, max: max)

  defp bound(nil), do: "nil"
  defp bound(value), do: value
end
