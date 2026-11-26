defmodule MaplibrexDemoWeb.LocaleController do
  use MaplibrexDemoWeb, :controller

  @supported_locales ~w(en es)

  # GET /locale?locale=es&return_to=/components/map
  def set(conn, %{"locale" => locale} = params) when locale in @supported_locales do
    conn
    |> put_session("locale", locale)
    |> redirect(to: local_path(params["return_to"]))
  end

  def set(conn, _params) do
    redirect(conn, to: ~p"/")
  end

  # Only ever return to a path on this site: "//host" and "/\host" are
  # protocol-relative URLs to another site, and anything else is not a path.
  defp local_path("/" <> rest = path) do
    if String.starts_with?(rest, ["/", "\\"]), do: ~p"/", else: path
  end

  defp local_path(_other), do: ~p"/"
end
