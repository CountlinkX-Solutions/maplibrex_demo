defmodule MaplibrexDemoWeb.CatalogueNav do
  @moduledoc """
  The navigation state every catalogue page shares, mounted for the whole
  `:catalogue` live session.

    * `@current_path` — the page's path and query string, which the locale
      switch returns to.
    * `@query` — the text of the component filter, which narrows the sidebar.

  The filter's events are handled here, before the page sees them, so pages
  only pass `@query` on to `Layouts.app/1`.
  """
  use MaplibrexDemoWeb, :verified_routes

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [attach_hook: 4, push_navigate: 2]

  alias MaplibrexDemoWeb.Catalogue

  # Component names are short; anything longer cannot match and is not kept.
  @max_query_length 60

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> assign(:query, "")
      |> assign(:current_path, "/")
      |> attach_hook(:current_path, :handle_params, &put_current_path/3)
      |> attach_hook(:component_filter, :handle_event, &handle_filter/3)

    {:cont, socket}
  end

  defp put_current_path(_params, uri, socket) do
    %URI{path: path, query: query} = URI.parse(uri)
    current = if query in [nil, ""], do: path, else: path <> "?" <> query

    {:cont, assign(socket, :current_path, current)}
  end

  defp handle_filter("filter_components", %{"q" => query}, socket) when is_binary(query) do
    {:halt, assign(socket, :query, String.slice(query, 0, @max_query_length))}
  end

  defp handle_filter("clear_filter", _params, socket) do
    {:halt, assign(socket, :query, "")}
  end

  # Enter in the filter opens the first match, the way a docs search does.
  defp handle_filter("open_first_match", %{"q" => query}, socket) when is_binary(query) do
    case Catalogue.search(query) do
      [first | _] ->
        {:halt, socket |> assign(:query, "") |> push_navigate(to: ~p"/components/#{first.name}")}

      [] ->
        {:halt, assign(socket, :query, String.slice(query, 0, @max_query_length))}
    end
  end

  defp handle_filter(_event, _params, socket), do: {:cont, socket}
end
