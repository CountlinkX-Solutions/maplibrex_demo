defmodule MaplibrexDemoWeb.DeckglLive do
  @moduledoc """
  deck.gl layers rendered as a MapLibre overlay: arcs, aggregated hexagons and
  a scatterplot.

  deck.gl is not part of the MaplibreX bundle. The first time a
  `<.deckgl_layer>` mounts, the hook dynamically imports the `@deck.gl/*`
  packages — applications that never use this component never download them.
  """
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}

  import MaplibreX.Components

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_viz, "arcs")
      |> assign(:flight_data, generate_flight_data())
      |> assign(:earthquake_data, generate_earthquake_data())
      |> assign(:city_data, generate_city_data())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.demo_page
      path={~p"/deckgl"}
      locale={@locale}
      title={gettext("Deck.GL Layers")}
      subtitle={gettext("3D ArcLayer, HexagonLayer, and ScatterplotLayer visualizations")}
    >
      <:map>
        <.map
          id="deckgl-map"
          center={[-95, 40]}
          zoom={4}
          pitch={45}
          bearing={0}
          style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
          class="absolute inset-0 h-full w-full"
        />

        <.navigation_control id="nav-control" map_id="deckgl-map" position="top-left" />

        <.deckgl_layer
          :if={@current_viz == "arcs"}
          id="flight-arcs"
          map_id="deckgl-map"
          layer_type="ArcLayer"
          data={@flight_data}
          pickable={true}
          props={
            %{
              "getSourcePosition" => "from",
              "getTargetPosition" => "to",
              "getSourceColor" => [255, 140, 0],
              "getTargetColor" => [255, 200, 0],
              "getWidth" => 2
            }
          }
        />

        <.deckgl_layer
          :if={@current_viz == "hexagons"}
          id="earthquake-hexagons"
          map_id="deckgl-map"
          layer_type="HexagonLayer"
          data={@earthquake_data}
          auto_highlight={true}
          props={
            %{
              "getPosition" => "coordinates",
              "elevationScale" => 50,
              "radius" => 50_000,
              "coverage" => 0.9,
              "extruded" => true,
              "colorRange" => [
                [1, 152, 189],
                [73, 227, 206],
                [216, 254, 181],
                [254, 237, 177],
                [254, 173, 84],
                [209, 55, 78]
              ]
            }
          }
        />

        <.deckgl_layer
          :if={@current_viz == "scatter"}
          id="city-scatter"
          map_id="deckgl-map"
          layer_type="ScatterplotLayer"
          data={@city_data}
          pickable={true}
          props={
            %{
              "getPosition" => "coordinates",
              "getRadius" => 10_000,
              "getFillColor" => [255, 140, 0],
              "radiusScale" => 6,
              "radiusMinPixels" => 2,
              "radiusMaxPixels" => 30
            }
          }
        />
      </:map>

      <:panel>
        <.panel_section label={gettext("Visualization")} class="space-y-1.5">
          <.option_button
            active={@current_viz == "arcs"}
            description={"ArcLayer — #{length(@flight_data)} #{gettext("routes")}"}
            phx-click="change_viz"
            phx-value-id="arcs"
          >
            {gettext("Flight Connections")}
          </.option_button>

          <.option_button
            active={@current_viz == "hexagons"}
            description={"HexagonLayer — #{length(@earthquake_data)} #{gettext("events")}"}
            phx-click="change_viz"
            phx-value-id="hexagons"
          >
            {gettext("Earthquake Density")}
          </.option_button>

          <.option_button
            active={@current_viz == "scatter"}
            description={"ScatterplotLayer — #{length(@city_data)} #{gettext("cities")}"}
            phx-click="change_viz"
            phx-value-id="scatter"
          >
            {gettext("City Points")}
          </.option_button>
        </.panel_section>

        <.panel_section label={gettext("About")}>
          <p class="text-xs leading-relaxed text-white/50">{about_text(@current_viz)}</p>
        </.panel_section>
      </:panel>

      <:telemetry>
        <.stat first label={gettext("Layer")} value={layer_name(@current_viz)} />
        <.stat label={gettext("Render")} value="3D" />
        <.stat label={gettext("Records")} value={record_count(assigns)} />
      </:telemetry>
    </.demo_page>
    """
  end

  @impl true
  def handle_event("change_viz", %{"id" => viz}, socket) do
    {:noreply, assign(socket, :current_viz, viz)}
  end

  def handle_event("map:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("deckgl:" <> _, _params, socket), do: {:noreply, socket}

  defp layer_name("arcs"), do: "ArcLayer"
  defp layer_name("hexagons"), do: "HexagonLayer"
  defp layer_name("scatter"), do: "ScatterplotLayer"
  defp layer_name(_), do: "—"

  defp record_count(%{current_viz: "arcs", flight_data: data}), do: length(data)
  defp record_count(%{current_viz: "hexagons", earthquake_data: data}), do: length(data)
  defp record_count(%{current_viz: "scatter", city_data: data}), do: length(data)
  defp record_count(_), do: 0

  defp about_text("arcs") do
    gettext(
      "ArcLayer renders animated arcs connecting source and target positions. Ideal for visualizing flight routes, migrations, or connections between locations."
    )
  end

  defp about_text("hexagons") do
    gettext(
      "HexagonLayer aggregates points into hexagonal bins with 3D elevation. Perfect for showing density and spatial distribution patterns."
    )
  end

  defp about_text("scatter") do
    gettext(
      "ScatterplotLayer efficiently renders thousands of points with customizable size and color. Ideal for showing individual geographic locations."
    )
  end

  defp about_text(_), do: ""

  # Sample data
  #
  # A rough sample of routes between the largest US cities.
  defp generate_flight_data do
    cities = [
      {"New York", [-74.0, 40.7]},
      {"Los Angeles", [-118.2, 34.0]},
      {"Chicago", [-87.6, 41.9]},
      {"Houston", [-95.4, 29.8]},
      {"Phoenix", [-112.1, 33.4]},
      {"Philadelphia", [-75.2, 39.9]},
      {"San Antonio", [-98.5, 29.4]},
      {"San Diego", [-117.2, 32.7]},
      {"Dallas", [-96.8, 32.8]},
      {"San Jose", [-121.9, 37.3]},
      {"Austin", [-97.7, 30.3]},
      {"Jacksonville", [-81.7, 30.3]},
      {"San Francisco", [-122.4, 37.8]},
      {"Columbus", [-83.0, 40.0]},
      {"Indianapolis", [-86.2, 39.8]},
      {"Seattle", [-122.3, 47.6]},
      {"Denver", [-104.9, 39.7]},
      {"Boston", [-71.1, 42.4]},
      {"Portland", [-122.7, 45.5]},
      {"Las Vegas", [-115.1, 36.2]}
    ]

    for {from_name, from_coords} <- cities,
        {to_name, to_coords} <- cities,
        from_name != to_name,
        :rand.uniform() > 0.7 do
      %{
        "from" => from_coords,
        "to" => to_coords,
        "from_city" => from_name,
        "to_city" => to_name
      }
    end
  end

  # Synthetic events across the California seismic zone.
  defp generate_earthquake_data do
    for _ <- 1..800 do
      %{
        "coordinates" => [-125.0 + :rand.uniform() * 15, 32.0 + :rand.uniform() * 10],
        "magnitude" => 2.0 + :rand.uniform() * 5
      }
    end
  end

  defp generate_city_data do
    for _ <- 1..500 do
      %{
        "coordinates" => [-125.0 + :rand.uniform() * 55, 25.0 + :rand.uniform() * 25],
        "population" => 10_000 + :rand.uniform(1_000_000)
      }
    end
  end
end
