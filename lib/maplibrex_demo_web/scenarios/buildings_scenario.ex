defmodule MaplibrexDemoWeb.Scenarios.BuildingsScenario do
  @moduledoc """
  Extruded buildings: a `fill-extrusion` GeoJSON layer whose height,
  opacity and colours are set from the server, and whose blocks report a
  click.

  The blocks are a synthetic grid generated for the demo with a fixed seed,
  placed over lower Manhattan for scale. They are not the real buildings.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale,
  # reports each map event to the page and keeps @theme on the page's light
  # or dark theme.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  # OpenFreeMap's basemap for the page's theme: the map's style follows @theme.
  defp basemap("dark"), do: "https://tiles.openfreemap.org/styles/dark"
  defp basemap("light"), do: "https://tiles.openfreemap.org/styles/positron"

  @center [-74.006, 40.7128]
  @types ~w(residential commercial office)
  @schemes ~w(height type uniform)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(center: @center, blocks: sample_blocks(), selected: nil, map_error: nil)
      |> assign(color_scheme: "height", height_scale: 1.0, opacity: 0.85)
      |> assign_options()

    {:ok, socket}
  end

  # Driven from the server: each control rebuilds the layer's paint.

  @impl true
  def handle_event("scheme", %{"scheme" => scheme}, socket) when scheme in @schemes do
    {:noreply, assign(socket, :color_scheme, scheme)}
  end

  def handle_event("scheme", _params, socket), do: {:noreply, socket}

  def handle_event("options", %{"height_scale" => height_scale, "opacity" => opacity}, socket) do
    {:noreply,
     socket
     |> assign(height_scale: float(height_scale), opacity: float(opacity))
     |> assign_options()}
  end

  # A click on a block carries its feature, with the generated properties.
  def handle_event("layer:feature_clicked", %{"feature" => %{"properties" => block}}, socket) do
    {:noreply, assign(socket, :selected, "#{block["type"]}, #{round(block["height"])} m")}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The layer's other events and the map's arrive too; this scenario does
  # not use them.
  def handle_event(_library_event, _payload, socket), do: {:noreply, socket}

  defp paint(scheme, height_scale, opacity) do
    %{
      "fill-extrusion-color" => color(scheme),
      "fill-extrusion-height" => ["*", ["get", "height"], height_scale],
      "fill-extrusion-base" => ["get", "base"],
      "fill-extrusion-opacity" => opacity,
      "fill-extrusion-vertical-gradient" => true
    }
  end

  # MapLibre expressions: a colour by height, by type, or one colour.
  defp color("height"),
    do: [
      "interpolate",
      ["linear"],
      ["get", "height"],
      20,
      "#f2c14e",
      80,
      "#5b8fd9",
      150,
      "#d64550"
    ]

  defp color("type"),
    do: [
      "match",
      ["get", "type"],
      "residential",
      "#f2c14e",
      "commercial",
      "#5b8fd9",
      "office",
      "#d64550",
      "#8a8fa3"
    ]

  defp color("uniform"), do: "#7c8fb0"

  # Sample data, generated with a fixed seed: a 15 by 15 grid of blocks of
  # random footprint, height and type, the same on every visit.
  defp sample_blocks do
    [center_lng, center_lat] = @center
    cells = for x <- 0..14, y <- 0..14, do: {x, y}

    {features, _seed} =
      Enum.map_reduce(cells, :rand.seed_s(:exsss, 1898), fn {x, y}, seed ->
        {width, seed} = :rand.uniform_s(seed)
        {depth, seed} = :rand.uniform_s(seed)
        {height, seed} = :rand.uniform_s(seed)
        {type, seed} = :rand.uniform_s(length(@types), seed)

        lng = center_lng + (x - 7) * 0.0016
        lat = center_lat + (y - 7) * 0.0012
        half_w = (0.0004 + width * 0.0002) / 2
        half_d = (0.0003 + depth * 0.00015) / 2

        feature = %{
          "type" => "Feature",
          "geometry" => %{
            "type" => "Polygon",
            "coordinates" => [
              [
                [lng - half_w, lat - half_d],
                [lng + half_w, lat - half_d],
                [lng + half_w, lat + half_d],
                [lng - half_w, lat + half_d],
                [lng - half_w, lat - half_d]
              ]
            ]
          },
          "properties" => %{
            "height" => Float.round(20 + height * 130, 1),
            "base" => 0,
            "type" => Enum.at(@types, type - 1)
          }
        }

        {feature, seed}
      end)

    %{"type" => "FeatureCollection", "features" => features}
  end

  defp schemes, do: @schemes

  defp assign_options(socket) do
    %{height_scale: height_scale, opacity: opacity} = socket.assigns
    assign(socket, :options, to_form(%{"height_scale" => height_scale, "opacity" => opacity}))
  end

  # Slider values arrive as strings: "2.5", "1".
  defp float(value) do
    case Float.parse(value) do
      {float, _rest} -> float
      :error -> 1.0
    end
  end
end
