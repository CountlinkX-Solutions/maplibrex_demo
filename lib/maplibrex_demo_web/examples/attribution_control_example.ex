defmodule MaplibrexDemoWeb.Examples.AttributionControlExample do
  @moduledoc """
  The example of `<.attribution_control>`: the map's attribution as a
  component, in the corner, the compact form and with the extra text the
  assigns choose.
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

  @positions ~w(top-left top-right bottom-left bottom-right)

  # Shown after the sources' own attribution when `custom` is on.
  @custom_attribution "MaplibreX demo"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(position: "bottom-right", compact: false, custom: false, map_error: nil)
      |> assign_options()

    {:ok, socket}
  end

  @impl true
  def handle_event("position", %{"position" => position}, socket)
      when position in @positions do
    {:noreply, assign(socket, :position, position)}
  end

  def handle_event("position", _params, socket), do: {:noreply, socket}

  def handle_event("options", params, socket) do
    {:noreply,
     socket
     |> assign(compact: params["compact"] == "true", custom: params["custom"] == "true")
     |> assign_options()}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The map's other events arrive too; this example does not use them.
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp assign_options(socket) do
    form = to_form(%{"compact" => socket.assigns.compact, "custom" => socket.assigns.custom})
    assign(socket, :options, form)
  end

  defp custom_attribution(true), do: @custom_attribution
  defp custom_attribution(false), do: nil

  defp positions, do: @positions
end
