defmodule MaplibrexDemoWeb.Examples.LineLayerExample do
  @moduledoc """
  The example of `<.line_layer>`: the main roads of OpenStreetMap, from
  OpenFreeMap's vector tiles, drawn over the basemap. Colour, width and
  dashes are paint set from the assigns.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

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
      |> assign(color: "#5b3fa6", selected: nil, map_error: nil)
      |> assign_options(3, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("color", %{"color" => color}, socket) do
    if Enum.any?(@colors, fn {_name, hex} -> hex == color end) do
      {:noreply, assign(socket, :color, color)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("options", %{"width" => width, "dashed" => dashed}, socket) do
    case Integer.parse(width) do
      {width, _rest} -> {:noreply, assign_options(socket, width, dashed == "true")}
      :error -> {:noreply, socket}
    end
  end

  # A click on a road carries its feature; OpenMapTiles names its kind
  # "class".
  def handle_event("layer:feature_clicked", %{"feature" => feature}, socket) do
    {:noreply, assign(socket, :selected, feature["properties"]["class"])}
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

  # Without dashes the property is left out, and MaplibreX sets it back to
  # MapLibre's default: a solid line.
  defp paint(color, width, dashed) do
    paint = %{"line-color" => color, "line-width" => width, "line-opacity" => 0.85}
    if dashed, do: Map.put(paint, "line-dasharray", [2, 1]), else: paint
  end

  defp assign_options(socket, width, dashed) do
    assign(socket,
      width: width,
      dashed: dashed,
      options: to_form(%{"width" => width, "dashed" => dashed})
    )
  end

  defp colors, do: @colors
end
