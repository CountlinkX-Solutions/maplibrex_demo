defmodule MaplibrexDemoWeb.LocaleController do
  use MaplibrexDemoWeb, :controller

  @supported_locales ~w(en es)

  # GET /locale?locale=es&return_to=/map
  def set(conn, %{"locale" => locale} = params) when locale in @supported_locales do
    return_to = Map.get(params, "return_to", "/")

    conn
    |> put_session("locale", locale)
    |> redirect(to: return_to)
  end

  def set(conn, _params) do
    redirect(conn, to: "/")
  end
end
