defmodule MaplibrexDemoWeb.RedirectController do
  @moduledoc """
  Sends the URLs of the pages the catalogue replaced to where the same
  thing is shown now, so bookmarks keep working.

  The router gives each route its destination in `conn.assigns.to`. The
  redirect is permanent (301): those pages will not come back.
  """
  use MaplibrexDemoWeb, :controller

  def show(conn, _params) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: conn.assigns.to)
  end
end
