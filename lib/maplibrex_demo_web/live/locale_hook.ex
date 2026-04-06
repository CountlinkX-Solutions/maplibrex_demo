defmodule MaplibrexDemoWeb.LocaleHook do
  import Phoenix.Component

  @supported_locales ~w(en es)

  def on_mount(:set_locale, _params, session, socket) do
    locale =
      case Map.get(session, "locale") do
        l when l in @supported_locales -> l
        _ -> "en"
      end

    Gettext.put_locale(locale)
    {:cont, assign(socket, :locale, locale)}
  end
end
