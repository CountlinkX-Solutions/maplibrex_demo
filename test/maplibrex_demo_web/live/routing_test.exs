defmodule MaplibrexDemoWeb.RoutingTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @pages [
    {"/", "Overview"},
    {"/components", "Components"},
    {"/components/map", "map"},
    {"/components/sky", "sky"},
    {"/scenarios", "Scenarios"},
    {"/scenarios/terrain_3d", "3D terrain flight"},
    {"/roadmap", "Roadmap"}
  ]

  for {path, title} <- @pages do
    test "#{path} mounts with the page title #{title}", %{conn: conn} do
      {:ok, view, _html} = live(conn, unquote(path))

      assert page_title(view) == unquote(title) <> " · MaplibreX"
    end
  end

  test "the overview replaces the old landing page", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#overview")
  end

  test "every catalogued component has a page", %{conn: conn} do
    for component <- MaplibrexDemoWeb.Catalogue.components() do
      {:ok, view, _html} = live(conn, ~p"/components/#{component.name}")
      assert has_element?(view, "#component-title", Atom.to_string(component.name))
    end
  end

  test "an unknown component is a 404", %{conn: conn} do
    assert_error_sent 404, fn -> get(conn, "/components/no_such_component") end
  end

  test "an unknown scenario is a 404", %{conn: conn} do
    assert_error_sent 404, fn -> get(conn, "/scenarios/no_such_scenario") end
  end

  # The pages that predate the catalogue. A bookmark lands on the page that
  # shows the same thing now; the tile server pages, removed, on the index.
  @old_pages [
    {"/map", "/components/map"},
    {"/markers", "/components/marker"},
    {"/terrain", "/scenarios/terrain_3d"},
    {"/heatmap", "/scenarios/heatmap"},
    {"/buildings", "/scenarios/buildings"},
    {"/particles", "/scenarios/particles"},
    {"/deckgl", "/scenarios/deckgl"},
    {"/tiles", "/components"},
    {"/ogc", "/components"}
  ]

  for {old, new} <- @old_pages do
    test "#{old}, replaced by the catalogue, redirects permanently to #{new}", %{conn: conn} do
      conn = get(conn, unquote(old))

      assert redirected_to(conn, 301) == unquote(new)
      assert {:ok, _view, _html} = live(build_conn(), unquote(new))
    end
  end

  test "no page needs a tile server any more, so none is configured" do
    assert Application.get_env(:maplibrex_demo, :tile_server_url) == nil
    assert Application.get_env(:maplibrex_demo, :fallback_style_url) == nil
  end

  test "the old pages and their chrome are gone" do
    for name <- ~w(MapLive TilesLive OgcFeaturesLive DeckglLive TerrainLive HeatmapLive
                   BuildingsLive MarkersLive ParticlesLive DemoComponents) do
      refute Code.ensure_loaded?(Module.concat(MaplibrexDemoWeb, name)), "#{name} still exists"
    end
  end
end
