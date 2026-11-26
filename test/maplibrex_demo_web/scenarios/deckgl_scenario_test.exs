defmodule MaplibrexDemoWeb.Scenarios.DeckglScenarioTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Scenarios.DeckglScenario

  @deck ~s([phx-hook="DeckGlLayerHook"])

  defp mount_scenario(conn) do
    {:ok, view, _html} = live_isolated(conn, DeckglScenario, session: %{"locale" => "en"})
    view
  end

  defp deck_configs(view) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(@deck)
    |> LazyHTML.attribute("data-config")
    |> Enum.map(&Jason.decode!/1)
  end

  test "draws the arc layer over its map at first", %{conn: conn} do
    view = mount_scenario(conn)

    assert has_element?(view, ~s(#scenario-deckgl-map[phx-hook="MapHook"]))

    assert has_element?(
             view,
             ~s([phx-hook="NavigationControlHook"][data-config*="scenario-deckgl-map"])
           )

    assert [%{"layerType" => "ArcLayer", "mapId" => "scenario-deckgl-map", "data" => routes}] =
             deck_configs(view)

    assert [%{"from" => [_, _], "to" => [_, _], "from_city" => _, "to_city" => _} | _] = routes
    assert has_element?(view, "#assign-records", Integer.to_string(length(routes)))
  end

  test "a layer button shows that layer alone, with :if", %{conn: conn} do
    view = mount_scenario(conn)

    view |> element("#scenario-deckgl-layer-hexagons") |> render_click()
    assert [%{"layerType" => "HexagonLayer", "data" => events}] = deck_configs(view)
    assert length(events) == 800
    assert has_element?(view, "#assign-records", "800")

    view |> element("#scenario-deckgl-layer-scatter") |> render_click()
    assert [%{"layerType" => "ScatterplotLayer"}] = deck_configs(view)
    assert has_element?(view, ~s(#scenario-deckgl-layer-scatter[aria-pressed="true"]))
    assert has_element?(view, "#assign-layer", "ScatterplotLayer")
  end

  test "an unknown layer is ignored", %{conn: conn} do
    view = mount_scenario(conn)

    render_click(view, "layer", %{"layer" => "trips"})

    assert has_element?(view, "#assign-layer", "ArcLayer")
  end

  test "generates the same sample data every time", %{conn: conn} do
    assert deck_configs(mount_scenario(conn)) == deck_configs(mount_scenario(conn))
  end

  test "labels its data as sample data and says it needs maplibre-gl 5", %{conn: conn} do
    view = mount_scenario(conn)

    assert has_element?(view, "#scenario-deckgl-sample-data")
    assert has_element?(view, "#scenario-deckgl-requirement", "maplibre-gl 5")
  end

  test "deckgl:click describes the clicked object", %{conn: conn} do
    view = mount_scenario(conn)

    render_hook(view, "deckgl:click", %{
      "layerId" => "scenario-deckgl-arcs",
      "object" => %{"from_city" => "Seattle", "to_city" => "Denver"},
      "coordinate" => [-110, 42]
    })

    assert has_element?(view, "#assign-selected", "Seattle → Denver")

    render_hook(view, "deckgl:click", %{
      "layerId" => "scenario-deckgl-hexagons",
      "object" => %{"count" => 12, "position" => [-118.2, 34.0]}
    })

    assert has_element?(view, "#assign-selected", "count: 12")
  end

  test "deckgl:layer_loaded and deckgl:error report the layer's state", %{conn: conn} do
    view = mount_scenario(conn)

    render_hook(view, "deckgl:layer_loaded", %{"layerId" => "scenario-deckgl-arcs"})
    assert has_element?(view, "#assign-status", "loaded")

    render_hook(view, "deckgl:error", %{"error" => "map.transform is undefined"})
    assert has_element?(view, ~s(#scenario-deckgl-map-error[role="alert"]), "map.transform")
    assert has_element?(view, "#assign-status", "error")
  end

  test "ignores hover and the map's events", %{conn: conn} do
    view = mount_scenario(conn)

    render_hook(view, "deckgl:hover", %{"layerId" => "scenario-deckgl-arcs", "object" => %{}})
    render_hook(view, "map:moved", %{"center" => [0, 0], "zoom" => 3})

    assert has_element?(view, "#assign-selected", "—")
  end
end
