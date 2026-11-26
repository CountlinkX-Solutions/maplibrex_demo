defmodule MaplibrexDemoWeb.Scenarios.TerrainScenario do
  @moduledoc """
  3D terrain flight: hillshading and 3D terrain from Mapterhorn's public
  elevation tiles, with the exaggeration set from the server and camera
  flights between mountain ranges that run in the browser.

  A scenario is a LiveView like a component example, with its template next
  to it (`terrain_scenario.html.heex`); `MaplibrexDemoWeb.ScenarioLive`
  runs it and shows both files.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  alias MaplibreX.Components.Map, as: MapCmd

  # Demo plumbing, not needed in an application: applies the page's locale
  # and reports each map event to the page.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  # Each flight ends on a camera pitched and turned towards a range; a lower
  # zoom keeps the camera above the peaks around it.
  @flights [
    %{id: "innsbruck", center: [11.3909, 47.2757], zoom: 12, pitch: 70, bearing: -20},
    %{id: "matterhorn", center: [7.6586, 45.9763], zoom: 11.5, pitch: 65, bearing: -125},
    %{id: "dolomites", center: [12.3047, 46.6455], zoom: 12.5, pitch: 70, bearing: 180}
  ]

  @impl true
  def mount(_params, _session, socket) do
    start = hd(@flights)

    socket =
      socket
      |> assign(start: start, exaggeration: 1.5, terrain: true, map_error: nil)
      |> assign(zoom: start.zoom, pitch: start.pitch, bearing: start.bearing)
      |> assign_options()

    {:ok, socket}
  end

  # Driven from the server: the terrain follows exaggeration, and :if turns
  # it off and on. The flights are JS commands and need no handler.

  @impl true
  def handle_event("options", %{"exaggeration" => exaggeration, "terrain" => terrain}, socket) do
    {:noreply,
     socket
     |> assign(exaggeration: float(exaggeration), terrain: terrain == "true")
     |> assign_options()}
  end

  # The camera comes back with map:moved after a flight or a drag.
  def handle_event("map:moved", %{"zoom" => zoom, "pitch" => pitch, "bearing" => bearing}, socket) do
    {:noreply,
     assign(socket, zoom: round_to(zoom), pitch: round_to(pitch), bearing: round_to(bearing))}
  end

  def handle_event(event, %{"error" => message}, socket)
      when event in ~w(map:error source:error terrain:error) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The sources', layer's and terrain's other events, and the map's, arrive
  # too; this scenario does not use them.
  def handle_event(_library_event, _payload, socket), do: {:noreply, socket}

  defp flights do
    names = %{
      "innsbruck" => gettext("Innsbruck"),
      "matterhorn" => gettext("Matterhorn"),
      "dolomites" => gettext("Dolomites")
    }

    Enum.map(@flights, &Map.put(&1, :name, names[&1.id]))
  end

  defp assign_options(socket) do
    %{exaggeration: exaggeration, terrain: terrain} = socket.assigns
    assign(socket, :options, to_form(%{"exaggeration" => exaggeration, "terrain" => terrain}))
  end

  defp float(value) do
    case Float.parse(value) do
      {float, _rest} -> float
      :error -> 1.0
    end
  end

  defp round_to(number) when is_integer(number), do: number
  defp round_to(number), do: Float.round(number, 2)
end
