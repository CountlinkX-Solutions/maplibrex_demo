defmodule MaplibrexDemoWeb.Examples.FillLayerExample do
  @moduledoc """
  The example of `<.fill_layer>`: the water of OpenStreetMap, from
  OpenFreeMap's vector tiles, filled over the basemap. Colour, opacity and
  outline are paint set from the assigns.
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
      |> assign(color: "#0f8b8d", selected: nil, map_error: nil)
      |> assign_options(0.6, true)

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

  def handle_event("options", %{"opacity" => opacity, "outline" => outline}, socket) do
    case Float.parse(opacity) do
      {opacity, _rest} -> {:noreply, assign_options(socket, opacity, outline == "true")}
      :error -> {:noreply, socket}
    end
  end

  # A click on the water carries its feature; OpenMapTiles names its kind
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

  # Without an outline the property is left out, and MaplibreX sets it back
  # to MapLibre's default: the fill colour.
  defp paint(color, opacity, outline) do
    paint = %{"fill-color" => color, "fill-opacity" => opacity}
    if outline, do: Map.put(paint, "fill-outline-color", "#1f2330"), else: paint
  end

  defp assign_options(socket, opacity, outline) do
    assign(socket,
      opacity: opacity,
      outline: outline,
      options: to_form(%{"opacity" => opacity, "outline" => outline})
    )
  end

  defp colors, do: @colors
end
