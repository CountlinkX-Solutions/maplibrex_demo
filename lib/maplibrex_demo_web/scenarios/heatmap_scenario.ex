defmodule MaplibrexDemoWeb.Scenarios.HeatmapScenario do
  @moduledoc """
  Earthquake-style heatmap: sample points drawn by a `heatmap` GeoJSON layer
  whose radius, intensity and opacity are set from the server.

  The points are generated for the demo, around six seismic zones of the
  United States, with a fixed seed so every visit draws the same map. They
  are not real earthquakes.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and reports each map event to the page.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @count 500

  # Centre and spread, in degrees, of each zone the sample points cluster
  # around: San Francisco Bay, Southern California, Cascadia, the Wasatch
  # Front, Yellowstone and New Madrid.
  @zones [
    {[-122.2, 37.8], 0.9},
    {[-117.4, 34.1], 1.3},
    {[-123.1, 45.6], 1.5},
    {[-111.9, 40.7], 0.8},
    {[-110.6, 44.5], 0.8},
    {[-89.6, 36.5], 1.0}
  ]

  # The colour ramp of the heatmap, from no density to the highest.
  @ramp [
    {0.0, "rgba(33, 102, 172, 0)"},
    {0.2, "rgb(103, 169, 207)"},
    {0.4, "rgb(209, 229, 240)"},
    {0.6, "rgb(253, 219, 199)"},
    {0.8, "rgb(239, 138, 98)"},
    {1.0, "rgb(178, 24, 43)"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(points: sample_points(), map_error: nil)
      |> assign(radius: 25, intensity: 0.6, opacity: 0.8)
      |> assign_options()

    {:ok, socket}
  end

  # Driven from the server: every slider rebuilds the layer's paint, and the
  # layer applies the properties that changed.

  @impl true
  def handle_event("options", params, socket) do
    %{"radius" => radius, "intensity" => intensity, "opacity" => opacity} = params

    {:noreply,
     socket
     |> assign(radius: number(radius), intensity: number(intensity), opacity: number(opacity))
     |> assign_options()}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The layer's events and the map's other events arrive too; this scenario
  # does not use them.
  def handle_event(_library_event, _payload, socket), do: {:noreply, socket}

  # Heavier events weigh more, and radius and intensity grow with the zoom so
  # the density reads the same as the map zooms in.
  defp paint(radius, intensity, opacity) do
    %{
      "heatmap-weight" => ["interpolate", ["linear"], ["get", "magnitude"], 2, 0, 6, 1],
      "heatmap-intensity" => ["interpolate", ["linear"], ["zoom"], 0, intensity, 9, intensity * 3],
      "heatmap-radius" => ["interpolate", ["linear"], ["zoom"], 0, radius / 4, 9, radius],
      "heatmap-color" =>
        ["interpolate", ["linear"], ["heatmap-density"]] ++
          Enum.flat_map(@ramp, fn {stop, color} -> [stop, color] end),
      "heatmap-opacity" => opacity
    }
  end

  defp legend_gradient do
    stops = Enum.map_join(@ramp, ", ", fn {stop, color} -> "#{color} #{trunc(stop * 100)}%" end)
    "background-image: linear-gradient(to right, #{stops})"
  end

  # Sample data, generated with a fixed seed: the same points on every visit.
  defp sample_points do
    zones = List.to_tuple(@zones)

    {features, _seed} =
      Enum.map_reduce(1..@count, :rand.seed_s(:exsss, 2026), fn i, seed ->
        {[lng, lat], spread} = elem(zones, rem(i, tuple_size(zones)))
        {dx, seed} = :rand.normal_s(seed)
        {dy, seed} = :rand.normal_s(seed)
        {m, seed} = :rand.uniform_s(seed)

        feature = %{
          "type" => "Feature",
          "geometry" => %{
            "type" => "Point",
            "coordinates" => [
              Float.round(lng + dx * spread, 3),
              Float.round(lat + dy * spread, 3)
            ]
          },
          "properties" => %{"magnitude" => Float.round(2 + m * 4, 1)}
        }

        {feature, seed}
      end)

    %{"type" => "FeatureCollection", "features" => features}
  end

  defp assign_options(socket) do
    %{radius: radius, intensity: intensity, opacity: opacity} = socket.assigns
    form = to_form(%{"radius" => radius, "intensity" => intensity, "opacity" => opacity})

    assign(socket, :options, form)
  end

  # Slider values arrive as strings: "40", "2.5", "0.5".
  defp number(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _ -> value |> Float.parse() |> elem(0)
    end
  end
end
