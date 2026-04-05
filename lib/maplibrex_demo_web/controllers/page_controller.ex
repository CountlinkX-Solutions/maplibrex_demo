defmodule MaplibrexDemoWeb.PageController do
  use MaplibrexDemoWeb, :controller

  plug :put_layout, html: false

  def home(conn, _params) do
    render(conn, :home)
  end
end
