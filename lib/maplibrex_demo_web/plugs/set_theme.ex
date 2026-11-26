defmodule MaplibrexDemoWeb.Plugs.SetTheme do
  @moduledoc """
  Reads the visitor's explicit theme choice from the `theme` cookie.

  The theme switch (see `assets/js/app.js`) writes the cookie in the browser.
  Reading it here lets the root layout render `data-theme` on `<html>`, so an
  explicit choice is applied before the first paint, with no inline script.
  Without the cookie, `:theme` is `nil` and the stylesheet follows the
  system's colour scheme.
  """
  import Plug.Conn

  @themes ~w(light dark)

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    theme =
      case conn.cookies["theme"] do
        theme when theme in @themes -> theme
        _ -> nil
      end

    assign(conn, :theme, theme)
  end
end
