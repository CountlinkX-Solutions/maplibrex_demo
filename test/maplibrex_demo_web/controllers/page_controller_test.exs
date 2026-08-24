defmodule MaplibrexDemoWeb.PageControllerTest do
  use MaplibrexDemoWeb.ConnCase

  test "the landing page lists every demo", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)

    assert html =~ "MaplibreX"
    assert html =~ "Explore the capabilities"

    for path <- ~w(/map /tiles /ogc /deckgl /terrain /heatmap /buildings /markers /particles) do
      assert html =~ ~s(href="#{path}"), "landing page is missing a link to #{path}"
    end
  end

  test "the landing page renders in Spanish once the locale is set", %{conn: conn} do
    html =
      conn
      |> get(~p"/locale?locale=es&return_to=/")
      |> get(~p"/")
      |> html_response(200)

    assert html =~ "Mapas Interactivos"
    refute html =~ "Explore the capabilities"
  end
end
