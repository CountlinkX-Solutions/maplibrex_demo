defmodule MaplibrexDemoWeb.Examples.ImageSourceExample do
  @moduledoc """
  The example of `<.image_source>`: an image placed at four coordinates and
  drawn by a raster layer. A new `url` from the server is applied to the
  source in place, so a timer on the server can animate it.
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

  # Sample radar images from the MapLibre GL JS documentation, and the
  # corners its examples place them at: top left, top right, bottom right,
  # bottom left, as [longitude, latitude].
  @frames 0..4
  @corners [[-80.425, 46.437], [-71.516, 46.437], [-71.516, 37.936], [-80.425, 37.936]]

  @tick_ms 700

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(frame: 0, corners: @corners, playing: false, status: "waiting", map_error: nil)
      |> assign_opacity(0.8)

    {:ok, socket}
  end

  # Driven from the server: the frame is the image's url, the opacity is
  # the layer's paint.

  @impl true
  def handle_event("frame", %{"frame" => frame}, socket) do
    case Integer.parse(frame) do
      {frame, ""} when frame in @frames -> {:noreply, assign(socket, :frame, frame)}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("options", %{"opacity" => opacity}, socket) do
    case Float.parse(opacity) do
      {opacity, _rest} -> {:noreply, assign_opacity(socket, opacity)}
      :error -> {:noreply, socket}
    end
  end

  # Playing is a timer on the server: every tick sets the next frame.
  def handle_event("play", _params, socket) do
    playing = not socket.assigns.playing
    if playing, do: Process.send_after(self(), :tick, @tick_ms)

    {:noreply, assign(socket, :playing, playing)}
  end

  # Events from the source: source:added says the image is on the map.

  def handle_event("source:added", _payload, socket) do
    {:noreply, assign(socket, :status, "added")}
  end

  def handle_event(event, %{"error" => message}, socket)
      when event in ["map:error", "source:error"] do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The source's other events, the layer's and the map's arrive too; this
  # example does not use them.
  def handle_event("source:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("layer:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  @impl true
  def handle_info(:tick, %{assigns: %{playing: true}} = socket) do
    Process.send_after(self(), :tick, @tick_ms)
    {:noreply, update(socket, :frame, &rem(&1 + 1, Enum.count(@frames)))}
  end

  def handle_info(:tick, socket), do: {:noreply, socket}

  defp assign_opacity(socket, opacity) do
    assign(socket, opacity: opacity, options: to_form(%{"opacity" => opacity}))
  end

  defp frames, do: @frames

  defp frame_url(frame), do: "https://maplibre.org/maplibre-gl-js/docs/assets/radar#{frame}.gif"
end
