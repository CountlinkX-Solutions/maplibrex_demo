defmodule MaplibrexDemoWeb.Scenarios.TerrainScenarioTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Scenarios.TerrainScenario

  @terrain "#terrain-scenario-terrain-map"

  defp mount_scenario(conn) do
    {:ok, view, _html} = live_isolated(conn, TerrainScenario, session: %{"locale" => "en"})
    view
  end

  defp set_options(view, options) do
    view
    |> element("#scenario-terrain-options")
    |> render_change(Map.merge(%{"exaggeration" => "1.5", "terrain" => "true"}, options))
  end

  test "the hillshading is warm on the light basemap and muted on the dark one", %{conn: conn} do
    view = mount_scenario(conn)
    hillshade = ~s(#scenario-hillshade[data-config*='"hillshade-highlight-color":)

    assert has_element?(view, hillshade <> ~s("#fff8e7']))

    render_hook(view, "theme", %{"theme" => "dark"})

    assert has_element?(view, hillshade <> ~s("#5e5646']))

    assert has_element?(
             view,
             ~s(#scenario-hillshade[data-config*='"hillshade-shadow-color":"#000000'])
           )
  end

  test "combines two DEM sources, hillshading, terrain and a navigation control", %{conn: conn} do
    view = mount_scenario(conn)

    assert has_element?(
             view,
             ~s(#scenario-terrain-map[phx-hook="MapHook"][data-config*="\\"maxPitch\\":85"])
           )

    assert has_element?(view, ~s(#scenario-terrain-dem[phx-hook="RasterDEMSourceHook"]))
    assert has_element?(view, ~s(#scenario-hillshade-dem[phx-hook="RasterDEMSourceHook"]))

    assert has_element?(
             view,
             ~s(#scenario-hillshade[phx-hook="HillshadeLayerHook"][data-config*="\\"sourceId\\":\\"scenario-hillshade-dem\\""])
           )

    assert has_element?(
             view,
             ~s(#{@terrain}[phx-hook="TerrainHook"][data-config*="\\"sourceId\\":\\"scenario-terrain-dem\\""])
           )

    assert has_element?(
             view,
             ~s([phx-hook="NavigationControlHook"][data-config*="scenario-terrain-map"])
           )
  end

  test "the exaggeration slider sets the terrain's exaggeration", %{conn: conn} do
    view = mount_scenario(conn)

    set_options(view, %{"exaggeration" => "2.2"})

    assert has_element?(view, ~s(#{@terrain}[data-config*="\\"exaggeration\\":2.2"]))
    assert has_element?(view, "#assign-exaggeration", "2.2")
  end

  test "the terrain checkbox turns the terrain off and on with :if", %{conn: conn} do
    view = mount_scenario(conn)

    set_options(view, %{"terrain" => "false"})
    refute has_element?(view, @terrain)
    assert has_element?(view, "#scenario-hillshade")

    set_options(view, %{"terrain" => "true"})
    assert has_element?(view, @terrain)
  end

  test "the flight buttons fly the camera in the browser", %{conn: conn} do
    view = mount_scenario(conn)

    for id <- ~w(innsbruck matterhorn dolomites) do
      assert has_element?(view, ~s(#scenario-terrain-fly-#{id}[phx-click*="maplibrex:fly_to"]))
      assert has_element?(view, ~s(#scenario-terrain-fly-#{id}[phx-click*="pitch"]))
    end
  end

  test "map:moved brings the camera into the assigns", %{conn: conn} do
    view = mount_scenario(conn)

    render_hook(view, "map:moved", %{
      "center" => [7.66, 45.98],
      "zoom" => 12.5,
      "pitch" => 72,
      "bearing" => -40
    })

    assert has_element?(view, "#assign-zoom", "12.5")
    assert has_element?(view, "#assign-pitch", "72")
    assert has_element?(view, "#assign-bearing", "-40")
  end

  test "map, source and terrain errors are shown over the map", %{conn: conn} do
    view = mount_scenario(conn)

    render_hook(view, "source:error", %{"source_id" => "scenario-terrain-dem", "error" => "503"})

    assert has_element?(view, ~s(#scenario-terrain-map-error[role="alert"]), "503")
  end
end
