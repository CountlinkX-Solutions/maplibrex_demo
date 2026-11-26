defmodule MaplibrexDemoWeb.Examples.TerrainExample do
  @moduledoc """
  The example of `<.terrain>`: 3D terrain from a raster DEM source, with its
  exaggeration and the map's pitch set from assigns, turned off and on with
  `:if`.
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
      |> assign(exaggeration: 1.5, pitch: 70, enabled: true, status: "waiting", map_error: nil)
      |> assign_options()

    {:ok, socket}
  end

  # Driven from the server: the terrain follows exaggeration, the map
  # follows pitch, and :if turns the terrain off and on.

  @impl true
  def handle_event("options", params, socket) do
    %{"exaggeration" => exaggeration, "pitch" => pitch, "enabled" => enabled} = params

    {:noreply,
     socket
     |> assign(
       exaggeration: float(exaggeration),
       pitch: number(pitch),
       enabled: enabled == "true"
     )
     |> assign_options()}
  end

  # Events from the terrain, and the camera from the map, so the pitch slider
  # follows a pitch set by dragging the map.

  def handle_event("terrain:enabled", _payload, socket) do
    {:noreply, assign(socket, :status, "enabled")}
  end

  def handle_event("terrain:disabled", _payload, socket) do
    {:noreply, assign(socket, :status, "disabled")}
  end

  def handle_event("terrain:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, status: "error", map_error: message)}
  end

  def handle_event("map:moved", %{"pitch" => pitch}, socket) do
    {:noreply, socket |> assign(:pitch, pitch) |> assign_options()}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The source's events and the map's other events arrive too; this example
  # does not use them.
  def handle_event("source:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp assign_options(socket) do
    %{exaggeration: exaggeration, pitch: pitch, enabled: enabled} = socket.assigns
    form = to_form(%{"exaggeration" => exaggeration, "pitch" => pitch, "enabled" => enabled})

    assign(socket, :options, form)
  end

  # Slider values arrive as strings. The terrain's exaggeration is a float,
  # "2" included; the pitch may be either.
  defp float(value) do
    case Float.parse(value) do
      {float, _rest} -> float
      :error -> 1.0
    end
  end

  defp number(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _ -> float(value)
    end
  end
end
