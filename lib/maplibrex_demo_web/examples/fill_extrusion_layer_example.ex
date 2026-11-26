defmodule MaplibrexDemoWeb.Examples.FillExtrusionLayerExample do
  @moduledoc """
  The example of `<.fill_extrusion_layer>`: OpenStreetMap's buildings in
  Midtown Manhattan, from OpenFreeMap's vector tiles, raised to their
  recorded height. The height is multiplied by an assign, and the colour is
  one too.
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
  defp basemap("light"), do: "https://tiles.openfreemap.org/styles/positron"

  @colors [
    {"purple", "#7c5cd6"},
    {"teal", "#0f8b8d"},
    {"orange", "#d9480f"},
    {"red", "#c92a2a"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(color: "#7c5cd6", selected: nil, map_error: nil)
      |> assign_scale(1.0)

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

  def handle_event("options", %{"scale" => scale}, socket) do
    case Float.parse(scale) do
      {scale, _rest} -> {:noreply, assign_scale(socket, scale)}
      :error -> {:noreply, socket}
    end
  end

  # A click carries every building under the pointer; the first is the
  # nearest. OpenMapTiles records its height in metres as render_height.
  def handle_event("layer:feature_clicked", %{"features" => [feature | _]}, socket) do
    {:noreply, assign(socket, :selected, "#{feature["properties"]["render_height"]} m")}
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

  defp paint(color, scale) do
    %{
      "fill-extrusion-color" => color,
      "fill-extrusion-height" => ["*", ["get", "render_height"], scale],
      "fill-extrusion-base" => ["*", ["get", "render_min_height"], scale],
      "fill-extrusion-opacity" => 0.85
    }
  end

  defp assign_scale(socket, scale) do
    assign(socket, scale: scale, options: to_form(%{"scale" => scale}))
  end

  defp colors, do: @colors
end
