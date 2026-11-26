defmodule MaplibrexDemoWeb.Plugs.SetThemeTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  # The theme switch stores an explicit choice in a cookie, so the server can
  # render it on <html> and the page never flashes the wrong theme on load.
  # Without a cookie the stylesheet follows the system preference.

  defp root(conn) do
    conn
    |> get(~p"/components/map")
    |> html_response(200)
    |> LazyHTML.from_document()
  end

  defp count(document, selector), do: document |> LazyHTML.query(selector) |> Enum.count()

  test "renders the theme stored in the cookie on the root element", %{conn: conn} do
    document = conn |> put_req_cookie("theme", "dark") |> root()

    assert count(document, ~s(html[data-theme="dark"])) == 1
  end

  test "leaves the theme to the system preference without a cookie", %{conn: conn} do
    assert count(root(conn), "html[data-theme]") == 0
  end

  test "ignores a theme it does not know", %{conn: conn} do
    document = conn |> put_req_cookie("theme", "neon") |> root()

    assert count(document, "html[data-theme]") == 0
  end

  test "serves its fonts from the application, not from a font host", %{conn: conn} do
    document = root(conn)

    assert count(document, ~s(link[href*="fonts.googleapis.com"])) == 0
    assert count(document, ~s(link[rel="preload"][as="font"][href^="/fonts/"])) > 0
  end

  test "sets the theme without an inline script", %{conn: conn} do
    assert count(root(conn), "script:not([src])") == 0
  end
end
