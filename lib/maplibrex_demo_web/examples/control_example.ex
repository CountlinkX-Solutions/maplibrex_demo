defmodule MaplibrexDemoWeb.Examples.ControlExample do
  @moduledoc """
  The example of `<.control>`: a form of your own, written in HEEx, placed
  on the map as a control. Its `phx-change` reaches this LiveView like any
  other form's, and its content follows the assigns.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  # OpenFreeMap's public styles.
  @basemaps ~w(liberty positron bright)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, basemap: "liberty", map_error: nil)}
  end

  # From the form inside the control: a new basemap is a new style for <.map>.
  @impl true
  def handle_event("basemap", %{"basemap" => basemap}, socket) when basemap in @basemaps do
    {:noreply, assign(socket, :basemap, basemap)}
  end

  def handle_event("basemap", _params, socket), do: {:noreply, socket}

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The map's other events arrive too; this example does not use them.
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp basemaps, do: @basemaps

  defp style_url(basemap), do: "https://tiles.openfreemap.org/styles/#{basemap}"

  defp basemap_name("liberty"), do: "Liberty"
  defp basemap_name("positron"), do: "Positron"
  defp basemap_name("bright"), do: "Bright"
end
