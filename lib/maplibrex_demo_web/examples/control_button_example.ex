defmodule MaplibrexDemoWeb.Examples.ControlButtonExample do
  @moduledoc """
  The example of `<.control_button>`: a map button whose `phx-click` reaches
  this LiveView. Each press tilts or flattens the map from the server, and
  the button's `active` state and tooltip follow the assigns.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, tilted: false, pitch: 0, presses: 0, map_error: nil)}
  end

  # From the button on the map.
  @impl true
  def handle_event("tilt", _params, socket) do
    tilted = not socket.assigns.tilted

    {:noreply,
     socket
     |> assign(tilted: tilted, pitch: if(tilted, do: 60, else: 0))
     |> update(:presses, &(&1 + 1))}
  end

  # The map can also be tilted by hand (right-drag or two fingers); map:moved
  # keeps the pitch assign in step with it.
  def handle_event("map:moved", %{"pitch" => pitch}, socket) do
    {:noreply, assign(socket, :pitch, pitch)}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The map's other events arrive too; this example does not use them.
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp tooltip(true), do: gettext("Flatten the map")
  defp tooltip(false), do: gettext("Tilt the map")
end
