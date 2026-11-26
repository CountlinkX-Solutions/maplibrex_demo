defmodule MaplibrexDemoWeb.Examples.SymbolLayerExample do
  @moduledoc """
  The example of `<.symbol_layer>`: text labels for OpenStreetMap's points
  of interest, from OpenFreeMap's vector tiles. The label's text and size
  are layout and its colour is paint, all set from the assigns.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  # The feature properties a label can show: the place's name, or its kind.
  @fields ~w(name class)

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
      |> assign(field: "name", color: "#5b3fa6", selected: nil, map_error: nil)
      |> assign_size(13)

    {:ok, socket}
  end

  # Driven from the server: text-field and text-size are layout, text-color
  # is paint; MaplibreX applies both in place.

  @impl true
  def handle_event("field", %{"field" => field}, socket) when field in @fields do
    {:noreply, assign(socket, :field, field)}
  end

  def handle_event("field", _params, socket), do: {:noreply, socket}

  def handle_event("color", %{"color" => color}, socket) do
    if Enum.any?(@colors, fn {_name, hex} -> hex == color end) do
      {:noreply, assign(socket, :color, color)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("options", %{"size" => size}, socket) do
    case Integer.parse(size) do
      {size, _rest} -> {:noreply, assign_size(socket, size)}
      :error -> {:noreply, socket}
    end
  end

  def handle_event("layer:feature_clicked", %{"feature" => feature}, socket) do
    {:noreply, assign(socket, :selected, feature["properties"]["name"])}
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

  # Text needs a font the map's glyphs provide; OpenFreeMap's styles serve
  # Noto Sans.
  defp layout(field, size) do
    %{
      "text-field" => ["get", field],
      "text-size" => size,
      "text-font" => ["Noto Sans Regular"],
      "text-max-width" => 8
    }
  end

  defp assign_size(socket, size) do
    assign(socket, size: size, options: to_form(%{"size" => size}))
  end

  defp fields, do: @fields
  defp colors, do: @colors
end
