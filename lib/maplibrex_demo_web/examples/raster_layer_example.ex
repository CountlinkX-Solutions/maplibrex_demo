defmodule MaplibrexDemoWeb.Examples.RasterLayerExample do
  @moduledoc """
  The example of `<.raster_layer>`: NASA's Blue Marble imagery drawn over
  the basemap, with its opacity, saturation and hue set from the assigns.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(map_error: nil) |> assign_options(0.7, 0, 0)}
  end

  @impl true
  def handle_event("options", params, socket) do
    %{"opacity" => opacity, "saturation" => saturation, "hue" => hue} = params

    with {opacity, _rest} <- Float.parse(opacity),
         {saturation, _rest} <- Float.parse(saturation),
         {hue, _rest} <- Integer.parse(hue) do
      {:noreply, assign_options(socket, opacity, saturation, hue)}
    else
      :error -> {:noreply, socket}
    end
  end

  def handle_event(event, %{"error" => message}, socket)
      when event in ["map:error", "source:error"] do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The layer's, the source's and the map's events arrive too; this example
  # does not use them.
  def handle_event("layer:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("source:" <> _event, _payload, socket), do: {:noreply, socket}
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp assign_options(socket, opacity, saturation, hue) do
    form = to_form(%{"opacity" => opacity, "saturation" => saturation, "hue" => hue})
    assign(socket, opacity: opacity, saturation: saturation, hue: hue, options: form)
  end
end
