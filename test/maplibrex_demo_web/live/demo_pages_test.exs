defmodule MaplibrexDemoWeb.DemoPagesTest do
  @moduledoc """
  Smoke tests for every demo page.

  These assert the LiveView mounts, renders its map container with the MapHook
  attached, and shows the shared chrome. They deliberately do not assert on
  MapLibre behaviour, which only exists in a browser.
  """
  use MaplibrexDemoWeb.ConnCase

  import Phoenix.LiveViewTest

  @pages [
    {"/map", "demo-map"},
    {"/tiles", "tiles-map"},
    {"/ogc", "ogc-map"},
    {"/deckgl", "deckgl-map"},
    {"/terrain", "terrain-map"},
    {"/heatmap", "heatmap-map"},
    {"/buildings", "buildings-map"},
    {"/markers", "markers-map"},
    {"/particles", "particles-map"}
  ]

  for {path, map_id} <- @pages do
    test "#{path} mounts and renders its map", %{conn: conn} do
      {:ok, _live, html} = live(conn, unquote(path))

      assert html =~ ~s(id="#{unquote(map_id)}")
      assert html =~ ~s(phx-hook="MapHook")
      # Shared chrome from DemoComponents.
      assert html =~ "Back to Demos"
    end
  end

  describe "/map" do
    test "switching style updates the map's config", %{conn: conn} do
      {:ok, live, _html} = live(conn, "/map")

      html =
        live
        |> element(~s(button[phx-value-url="https://tiles.openfreemap.org/styles/dark"]))
        |> render_click()

      assert html =~ "tiles.openfreemap.org/styles/dark"
    end

    test "adding a marker renders another marker hook", %{conn: conn} do
      {:ok, live, html} = live(conn, "/map")
      before = count(html, ~s(phx-hook="MarkerHook"))

      html = live |> element(~s(button[phx-click="add_marker"])) |> render_click()

      assert count(html, ~s(phx-hook="MarkerHook")) == before + 1
    end

    test "clearing markers removes them all", %{conn: conn} do
      {:ok, live, _html} = live(conn, "/map")

      html = live |> element(~s(button[phx-click="clear_markers"])) |> render_click()

      assert count(html, ~s(phx-hook="MarkerHook")) == 0
    end
  end

  describe "/markers" do
    test "filtering by category hides the other markers", %{conn: conn} do
      {:ok, live, html} = live(conn, "/markers")
      all = count(html, ~s(phx-hook="MarkerHook"))

      html = live |> element(~s(button[phx-value-category="park"])) |> render_click()

      assert count(html, ~s(phx-hook="MarkerHook")) < all
    end
  end

  describe "/tiles" do
    test "reports the tile server as unreachable and falls back", %{conn: conn} do
      {:ok, live, _html} = live(conn, "/tiles")

      # No tile server runs during tests, so the probe must fail and the page
      # must fall back to the public basemap rather than render a blank map.
      html = render(live)
      assert html =~ "Server unreachable"
      assert html =~ "demotiles.maplibre.org"
    end
  end

  describe "/ogc" do
    test "reports the feature server as unreachable", %{conn: conn} do
      {:ok, live, _html} = live(conn, "/ogc")

      assert render(live) =~ "Server unreachable"
    end
  end

  defp count(html, needle) do
    html |> String.split(needle) |> length() |> Kernel.-(1)
  end
end
