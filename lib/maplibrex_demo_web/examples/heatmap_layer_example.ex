defmodule MaplibrexDemoWeb.Examples.HeatmapLayerExample do
  @moduledoc """
  The example of `<.heatmap_layer>`: where OpenStreetMap's points of
  interest crowd together in central Paris, from OpenFreeMap's vector
  tiles. The heatmap's radius and intensity are paint set from the assigns.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(on_map: false, map_error: nil)
      |> assign_options(10, 0.3)

    {:ok, socket}
  end

  @impl true
  def handle_event("options", %{"radius" => radius, "intensity" => intensity}, socket) do
    with {radius, _rest} <- Integer.parse(radius),
         {intensity, _rest} <- Float.parse(intensity) do
      {:noreply, assign_options(socket, radius, intensity)}
    else
      :error -> {:noreply, socket}
    end
  end

  # A heatmap reports no clicks; layer:added says it is on the map.
  def handle_event("layer:added", _payload, socket) do
    {:noreply, assign(socket, :on_map, true)}
  end

  def handle_event(event, %{"error" => message}, socket)
      when event in ["map:error", "source:error"] do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The layer's other events, the source's and the map's arrive too; this
  # example does not use them.
  def handle_event("layer:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("source:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  # Density from transparent through the accent to orange.
  defp paint(radius, intensity) do
    %{
      "heatmap-radius" => radius,
      "heatmap-intensity" => intensity,
      "heatmap-opacity" => 0.8,
      "heatmap-color" => [
        "interpolate",
        ["linear"],
        ["heatmap-density"],
        0,
        "rgba(91, 63, 166, 0)",
        0.3,
        "rgba(91, 63, 166, 0.6)",
        0.7,
        "#c92a2a",
        1,
        "#f59f00"
      ]
    }
  end

  defp assign_options(socket, radius, intensity) do
    assign(socket,
      radius: radius,
      intensity: intensity,
      options: to_form(%{"radius" => radius, "intensity" => intensity})
    )
  end
end
