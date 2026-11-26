defmodule MaplibrexDemoWeb.Examples.Plumbing do
  @moduledoc """
  The demo-only wiring every example mounts with `on_mount`. An application
  using MaplibreX needs none of it.

    * Applies the page's locale. An example is a LiveView of its own, in its
      own process, so it does not inherit the page's Gettext locale; the
      component page passes it in the session.
    * Copies every library event the example receives (`map:moved`,
      `marker:drag_end`, ...) to the component page, which shows the last
      payload of each in its Events tab. The example's own `handle_event/3`
      still receives the event unchanged.
    * Keeps `@theme` on the page's theme, `"light"` or `"dark"`, so that the
      example's basemap can follow it: `<.map style={basemap(@theme)}>`.
      The browser sends the theme in effect when the example connects (the
      LiveSocket's `params`) and in a `"theme"` event whenever it changes
      (the `ExampleTheme` hook of `ExampleComponents.example_frame/1`; see
      `assets/js/theme.js`). Until the browser has said, it is `"light"`.
      The event stops here, so examples need no clause for it.
  """
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [attach_hook: 4, connected?: 1, get_connect_params: 1]

  @locales ~w(en es)
  @themes ~w(light dark)

  def on_mount(:default, _params, session, socket) do
    locale = if session["locale"] in @locales, do: session["locale"], else: "en"
    Gettext.put_locale(locale)

    socket =
      socket
      |> assign(:theme, connect_theme(socket))
      |> attach_hook(:report_events, :handle_event, &report_event/3)
      |> attach_hook(:follow_theme, :handle_event, &follow_theme/3)

    {:cont, socket}
  end

  # The theme the browser connected with, or "light" while it has not. A
  # nested LiveView has no connect params in the page's first, static render.
  defp connect_theme(socket) do
    with true <- connected?(socket),
         %{"theme" => theme} when theme in @themes <- get_connect_params(socket) do
      theme
    else
      _ -> "light"
    end
  end

  # Library events are namespaced ("map:moved"); the example's own events
  # ("go", "camera") stay private to it.
  defp report_event(event, params, socket) do
    if socket.parent_pid && String.contains?(event, ":") do
      send(socket.parent_pid, {:example_event, event, params})
    end

    {:cont, socket}
  end

  defp follow_theme("theme", %{"theme" => theme}, socket) when theme in @themes do
    {:halt, assign(socket, :theme, theme)}
  end

  defp follow_theme("theme", _params, socket), do: {:halt, socket}
  defp follow_theme(_event, _params, socket), do: {:cont, socket}
end
