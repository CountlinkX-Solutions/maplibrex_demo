defmodule MaplibrexDemoWeb.Examples.ControlExample do
  @moduledoc """
  The example of `<.control>`: a form of your own, written in HEEx, placed
  on the map as a control. Its `phx-change` reaches this LiveView like any
  other form's, and its content follows the assigns.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale,
  # copies each map event to the page's Events tab and keeps @theme on the
  # page's light or dark theme.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  # OpenFreeMap's public styles: those the control offers in the page's
  # light theme, and those it offers in the dark one.
  @basemaps %{"light" => ~w(liberty positron bright), "dark" => ~w(dark fiord)}

  @impl true
  def mount(_params, _session, socket) do
    # The basemap chosen in each theme: switching the theme switches to the
    # other theme's choice, and back.
    {:ok, assign(socket, chosen: %{"light" => "liberty", "dark" => "dark"}, map_error: nil)}
  end

  # From the form inside the control: a new basemap is a new style for <.map>.
  @impl true
  def handle_event("basemap", %{"basemap" => basemap}, socket) do
    theme = socket.assigns.theme

    if basemap in @basemaps[theme] do
      {:noreply, update(socket, :chosen, &Map.put(&1, theme, basemap))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("basemap", _params, socket), do: {:noreply, socket}

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The map's other events arrive too; this example does not use them.
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp basemaps(theme), do: @basemaps[theme]

  defp style_url(basemap), do: "https://tiles.openfreemap.org/styles/#{basemap}"

  defp basemap_name("liberty"), do: "Liberty"
  defp basemap_name("positron"), do: "Positron"
  defp basemap_name("bright"), do: "Bright"
  defp basemap_name("dark"), do: "Dark"
  defp basemap_name("fiord"), do: "Fiord"
end
