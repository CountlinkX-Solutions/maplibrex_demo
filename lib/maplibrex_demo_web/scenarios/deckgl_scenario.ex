defmodule MaplibrexDemoWeb.Scenarios.DeckglScenario do
  @moduledoc """
  deck.gl layers: an arc, a hexagon and a scatterplot layer drawn over the
  map by `<.deckgl_layer>`, one at a time, with a click on an object coming
  back as `deckgl:click`.

  deck.gl is loaded the first time a layer mounts. It needs maplibre-gl 5
  (library issue #11), which this demo pins in `assets/package.json`.

  The data is sample data generated with a fixed seed: connections between
  twenty US cities, events around four Californian centres and points
  spread over the country. None of it is real.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and reports each map event to the page.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @layers [{"arcs", "ArcLayer"}, {"hexagons", "HexagonLayer"}, {"scatter", "ScatterplotLayer"}]

  @cities [
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

  @impl true
  def mount(_params, _session, socket) do
    seed = :rand.seed_s(:exsss, 1984)
    {routes, seed} = sample_routes(seed)

    {events, seed} =
      sample_points(
        800,
        [[-122.2, 37.8], [-118.2, 34.0], [-116.5, 33.4], [-120.6, 36.1]],
        0.6,
        seed
      )

    {points, _seed} = sample_points(500, [[-98.0, 38.5]], 9.0, seed)

    {:ok,
     assign(socket,
       layer: "arcs",
       routes: routes,
       events: events,
       points: points,
       status: "loading",
       selected: nil,
       map_error: nil
     )}
  end

  # Driven from the server: :if shows one layer at a time.

  @impl true
  def handle_event("layer", %{"layer" => layer}, socket) do
    if List.keymember?(@layers, layer, 0) do
      {:noreply, assign(socket, layer: layer, status: "loading", selected: nil)}
    else
      {:noreply, socket}
    end
  end

  # Events from deck.gl: the layer has loaded, an object was clicked, or the
  # layer failed (for example under maplibre-gl 6).

  def handle_event("deckgl:layer_loaded", _payload, socket) do
    {:noreply, assign(socket, :status, "loaded")}
  end

  def handle_event("deckgl:click", %{"object" => object}, socket) do
    {:noreply, assign(socket, :selected, describe(object))}
  end

  def handle_event("deckgl:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, status: "error", map_error: message)}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # deckgl:hover, the drag events and the map's events arrive too; this
  # scenario does not use them.
  def handle_event(_library_event, _payload, socket), do: {:noreply, socket}

  defp describe(%{"from_city" => from, "to_city" => to}), do: "#{from} → #{to}"
  defp describe(%{"count" => count}), do: "count: #{count}"
  defp describe(%{"value" => value}), do: "value: #{value}"
  defp describe(_object), do: "—"

  defp layers, do: @layers
  defp layer_type(layer), do: layer |> then(&List.keyfind(@layers, &1, 0)) |> elem(1)

  defp records(%{layer: "arcs", routes: routes}), do: length(routes)
  defp records(%{layer: "hexagons", events: events}), do: length(events)
  defp records(%{layer: "scatter", points: points}), do: length(points)

  # Sample data, generated with a fixed seed: a quarter of the possible
  # connections between the cities above.
  defp sample_routes(seed) do
    pairs =
      for {from, i} <- Enum.with_index(@cities),
          {to, j} <- Enum.with_index(@cities),
          i < j,
          do: {from, to}

    Enum.flat_map_reduce(pairs, seed, fn {{from_city, from}, {to_city, to}}, seed ->
      {pick, seed} = :rand.uniform_s(seed)
      route = %{"from" => from, "to" => to, "from_city" => from_city, "to_city" => to_city}
      {if(pick < 0.25, do: [route], else: []), seed}
    end)
  end

  # Sample data: `count` points scattered around the given centres, each
  # with a value between 0 and 1.
  defp sample_points(count, centres, spread, seed) do
    centres = List.to_tuple(centres)

    Enum.map_reduce(1..count, seed, fn i, seed ->
      [lng, lat] = elem(centres, rem(i, tuple_size(centres)))
      {dx, seed} = :rand.normal_s(seed)
      {dy, seed} = :rand.normal_s(seed)
      {value, seed} = :rand.uniform_s(seed)

      point = %{
        "coordinates" => [
          Float.round(lng + dx * spread, 3),
          Float.round(lat + dy * spread / 2, 3)
        ],
        "value" => Float.round(value, 2)
      }

      {point, seed}
    end)
  end
end
