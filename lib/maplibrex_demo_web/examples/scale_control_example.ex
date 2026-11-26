defmodule MaplibrexDemoWeb.Examples.ScaleControlExample do
  @moduledoc """
  The example of `<.scale_control>`: a scale bar in the unit, width and
  corner the assigns choose, following the map's zoom.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @units ~w(metric imperial nautical)
  @positions ~w(top-left top-right bottom-left bottom-right)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(unit: "metric", position: "bottom-left", map_error: nil)
      |> assign(max_width: 120, zoom: 11)
      |> assign_options()

    {:ok, socket}
  end

  @impl true
  def handle_event("unit", %{"unit" => unit}, socket) when unit in @units do
    {:noreply, assign(socket, :unit, unit)}
  end

  def handle_event("position", %{"position" => position}, socket)
      when position in @positions do
    {:noreply, assign(socket, :position, position)}
  end

  def handle_event("options", %{"max_width" => max_width, "zoom" => zoom}, socket) do
    {:noreply,
     socket
     |> assign(max_width: number(max_width), zoom: number(zoom))
     |> assign_options()}
  end

  def handle_event(event, _params, socket) when event in ~w(unit position) do
    {:noreply, socket}
  end

  # Zooming the map by hand changes the scale too; map:moved brings the zoom
  # back so the slider stays in step.
  def handle_event("map:moved", %{"zoom" => zoom}, socket) do
    {:noreply, socket |> assign(:zoom, zoom) |> assign_options()}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp assign_options(socket) do
    form = to_form(%{"max_width" => socket.assigns.max_width, "zoom" => socket.assigns.zoom})
    assign(socket, :options, form)
  end

  defp units, do: @units
  defp positions, do: @positions

  # Slider values arrive as strings: "200", "6.5".
  defp number(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _ -> value |> Float.parse() |> elem(0)
    end
  end
end
