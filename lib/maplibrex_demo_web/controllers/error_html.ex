defmodule MaplibrexDemoWeb.ErrorHTML do
  @moduledoc """
  The pages shown for errors on HTML requests. `render_errors` in
  config/config.exs renders them without a layout.

  404 and 500 are standalone documents on the catalogue's tokens: a top bar
  with the wordmark, what went wrong and a way back. They load the stylesheet
  and nothing else, so they still render when the error left the shell, the
  session or LiveView unusable. Any other status keeps Phoenix's plain-text
  message.
  """
  use MaplibrexDemoWeb, :html

  embed_templates "error_html/*"

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  @doc """
  The document around an error page.

  The language is Gettext's current locale, which the browser pipeline has
  set when the request got that far; otherwise it is English. The theme is
  the visitor's explicit choice from the `theme` cookie, if any.
  """
  attr :title, :string, required: true, doc: "the document's title"
  attr :heading, :string, default: nil, doc: "the page's heading; the title when nil"
  attr :conn, :any, default: nil
  slot :inner_block, required: true, doc: "what went wrong"

  slot :action, required: true, doc: "the ways back, primary first" do
    attr :href, :string, required: true
  end

  def error_page(assigns) do
    assigns =
      assign(assigns,
        locale: Gettext.get_locale(MaplibrexDemoWeb.Gettext),
        theme: theme(assigns.conn)
      )

    ~H"""
    <!DOCTYPE html>
    <html lang={@locale} data-theme={@theme}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{@title} · MaplibreX</title>
        <link rel="stylesheet" href={~p"/assets/css/app.css"} />
      </head>
      <body class="bg-canvas text-ink antialiased">
        <header class="h-topbar border-b border-line">
          <div class="flex h-full items-center px-4 sm:px-6 lg:px-7">
            <a
              href={~p"/"}
              class="rounded-ui text-heading leading-none font-black tracking-tight text-accent-ink"
            >
              MaplibreX
            </a>
          </div>
        </header>

        <main id="main" class="px-4 pt-12 pb-24 sm:px-6 sm:pt-16 lg:px-7">
          <div class="max-w-measure">
            <h1 class="text-display font-black tracking-tight">{@heading || @title}</h1>
            <div id="error-message" class="mt-3 text-lead text-ink-muted">
              {render_slot(@inner_block)}
            </div>
            <nav
              id="error-actions"
              aria-label={gettext("Ways back")}
              class="mt-8 flex flex-wrap gap-3"
            >
              <a
                :for={{action, index} <- Enum.with_index(@action)}
                href={action.href}
                class={[
                  "inline-flex h-10 items-center gap-2 rounded-ui px-4 text-ui font-bold",
                  if(index == 0,
                    do: "bg-accent text-on-accent hover:bg-accent-hover",
                    else: "border border-line-strong text-ink hover:bg-surface"
                  )
                ]}
              >
                {render_slot(action)}
              </a>
            </nav>
          </div>
        </main>
      </body>
    </html>
    """
  end

  defp theme(%Plug.Conn{} = conn),
    do: MaplibrexDemoWeb.Plugs.SetTheme.call(conn, []).assigns.theme

  defp theme(_conn), do: nil

  defp request_path(%Plug.Conn{request_path: path}), do: path
  defp request_path(_conn), do: "/"
end
