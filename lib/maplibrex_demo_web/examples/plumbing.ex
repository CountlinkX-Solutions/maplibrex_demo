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
  """
  import Phoenix.LiveView, only: [attach_hook: 4]

  @locales ~w(en es)

  def on_mount(:default, _params, session, socket) do
    locale = if session["locale"] in @locales, do: session["locale"], else: "en"
    Gettext.put_locale(locale)

    {:cont, attach_hook(socket, :report_events, :handle_event, &report_event/3)}
  end

  # Library events are namespaced ("map:moved"); the example's own events
  # ("go", "camera") stay private to it.
  defp report_event(event, params, socket) do
    if socket.parent_pid && String.contains?(event, ":") do
      send(socket.parent_pid, {:example_event, event, params})
    end

    {:cont, socket}
  end
end
