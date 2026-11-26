defmodule MaplibrexDemoWeb.Examples.CircleLayerExample do
  @moduledoc """
  The example of `<.circle_layer>`: the point of every country in MapLibre's
  demo tiles drawn as a circle, whose colour and radius are paint set from
  the assigns, with a click coming back as `layer:feature_clicked`.
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
      |> assign_radius(6)

    {:ok, socket}
  end

  # Driven from the server: paint is an assign, so a new value repaints the
  # layer in place.

  @impl true
  def handle_event("color", %{"color" => color}, socket) do
    if Enum.any?(@colors, fn {_name, hex} -> hex == color end) do
      {:noreply, assign(socket, :color, color)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("options", %{"radius" => radius}, socket) do
    case Integer.parse(radius) do
      {radius, _rest} -> {:noreply, assign_radius(socket, radius)}
      :error -> {:noreply, socket}
    end
  end

  # A click on a circle carries the feature under the pointer.
  def handle_event("layer:feature_clicked", %{"feature" => feature}, socket) do
    {:noreply, assign(socket, :selected, feature["properties"]["NAME"])}
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

  defp assign_radius(socket, radius) do
    assign(socket, radius: radius, options: to_form(%{"radius" => radius}))
  end

  defp colors, do: @colors
end
