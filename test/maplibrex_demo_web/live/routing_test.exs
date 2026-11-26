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
end
