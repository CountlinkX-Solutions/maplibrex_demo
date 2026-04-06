defmodule MaplibrexDemoWeb.Plugs.SetLocale do
  import Plug.Conn

  @supported_locales ~w(en es)

  def init(opts), do: opts

  def call(conn, _opts) do
    locale =
      case get_session(conn, "locale") do
        l when l in @supported_locales -> l
        _ -> "en"
      end

    Gettext.put_locale(locale)
    assign(conn, :locale, locale)
  end
end
