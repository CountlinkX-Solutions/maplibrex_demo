defmodule MaplibrexDemoWeb.Examples.FullscreenControlExample do
  @moduledoc """
  The example of `<.fullscreen_control>`: a button that shows the map, or
  the element `container_id` names, in full screen, and reports it with
  `fullscreen:entered` and `fullscreen:exited`.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @positions ~w(top-left top-right bottom-left bottom-right)

  # What goes full screen: the map alone (no container_id), or this whole
  # example, controls included.
  @containers %{"map" => nil, "example" => "fullscreen-example"}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, position: "top-right", container_id: nil, fullscreen: false, map_error: nil)}
  end

  @impl true
  def handle_event("position", %{"position" => position}, socket)
      when position in @positions do
    {:noreply, assign(socket, :position, position)}
  end

  def handle_event("container", %{"container" => container}, socket)
      when is_map_key(@containers, container) do
    {:noreply, assign(socket, :container_id, @containers[container])}
  end

  def handle_event(event, _params, socket) when event in ~w(position container) do
    {:noreply, socket}
  end

  # Events from the control: the browser's full screen was entered or left,
  # by the button or by Escape.

  def handle_event("fullscreen:entered", _payload, socket) do
    {:noreply, assign(socket, :fullscreen, true)}
  end

  def handle_event("fullscreen:exited", _payload, socket) do
    {:noreply, assign(socket, :fullscreen, false)}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp positions, do: @positions
  defp containers, do: Enum.sort(@containers)
end
