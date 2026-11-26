defmodule MaplibrexDemoWeb.Examples.BackgroundLayerExample do
  @moduledoc """
  The example of `<.background_layer>`: on a style with no layers of its
  own, the background is the sea behind the countries of MapLibre's demo
  tiles. Its colour and opacity are paint set from the assigns.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @colors [
    {"sea", "#b9d9eb"},
    {"teal", "#0f8b8d"},
    {"lavender", "#eee9f8"},
    {"ink", "#1f2330"}
  ]

  # A style with no sources or layers: the map draws only the layers below.
  @blank_style %{"version" => 8, "sources" => %{}, "layers" => []}

  @impl true
  def mount(_params, _session, socket) do
    # The sea starts light blue in the light theme and ink in the dark one
    # (Plumbing sets @theme); after that it is the visitor's choice.
    color = if socket.assigns.theme == "dark", do: "#1f2330", else: "#b9d9eb"

    socket =
      socket
      |> assign(color: color, map_error: nil)
      |> assign_opacity(1.0)

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

  def handle_event("options", %{"opacity" => opacity}, socket) do
    case Float.parse(opacity) do
      {opacity, _rest} -> {:noreply, assign_opacity(socket, opacity)}
      :error -> {:noreply, socket}
    end
  end

  def handle_event(event, %{"error" => message}, socket)
      when event in ["map:error", "source:error"] do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The layers', the source's and the map's events arrive too; this example
  # does not use them.
  def handle_event("layer:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("source:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp assign_opacity(socket, opacity) do
    assign(socket, opacity: opacity, options: to_form(%{"opacity" => opacity}))
  end

  defp colors, do: @colors
  defp blank_style, do: @blank_style

  # The land: white in the light theme, dark grey in the dark one.
  defp land("dark"), do: "#3d4255"
  defp land("light"), do: "#ffffff"
end
