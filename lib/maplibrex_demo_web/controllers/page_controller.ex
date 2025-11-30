defmodule MaplibrexDemoWeb.PageController do
  use MaplibrexDemoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
