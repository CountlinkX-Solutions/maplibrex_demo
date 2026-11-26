defmodule MaplibrexDemoWeb.Examples.PopupExample do
  @moduledoc """
  The example of `<.popup>`: a popup on its own, not attached to a marker,
  whose place, content and open state are assigns, with `popup:opened` and
  `popup:closed` keeping the server in step when the visitor closes it.
  """
  use MaplibrexDemoWeb, :live_view

  import MaplibreX.Components
  import MaplibrexDemoWeb.Examples.ExampleComponents

  # Demo plumbing, not needed in an application: applies the page's locale
  # and copies each map event to the page's Events tab.
  on_mount MaplibrexDemoWeb.Examples.Plumbing

  @places [
    %{id: "colosseum", lng_lat: [12.4922, 41.8902]},
    %{id: "pantheon", lng_lat: [12.4769, 41.8986]},
    %{id: "trevi", lng_lat: [12.4833, 41.9009]}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(place: hd(@places), last_event: nil, map_error: nil)
     |> assign_open(true)}
  end

  # Driven from the server: a place moves the popup and opens it; the
  # checkbox opens and closes it.

  @impl true
  def handle_event("place", %{"place" => id}, socket) do
    case Enum.find(@places, &(&1.id == id)) do
      nil -> {:noreply, socket}
      place -> {:noreply, socket |> assign(:place, place) |> assign_open(true)}
    end
  end

  def handle_event("options", %{"open" => open}, socket) do
    {:noreply, assign_open(socket, open == "true")}
  end

  # Events from the popup. Its close button and a click on the map close it
  # in the browser; popup:closed tells the server, so `open` stays true to
  # what the visitor sees.

  def handle_event("popup:opened", _payload, socket) do
    {:noreply, socket |> assign(:last_event, "popup:opened") |> assign_open(true)}
  end

  def handle_event("popup:closed", _payload, socket) do
    {:noreply, socket |> assign(:last_event, "popup:closed") |> assign_open(false)}
  end

  def handle_event("map:error", %{"error" => message}, socket) do
    {:noreply, assign(socket, :map_error, message)}
  end

  # The map's other events arrive too; this example does not use them.
  def handle_event("map:" <> _event, _payload, socket), do: {:noreply, socket}

  defp assign_open(socket, open) do
    assign(socket, open: open, options: to_form(%{"open" => open}))
  end

  defp places, do: @places

  defp name("colosseum"), do: gettext("Colosseum")
  defp name("pantheon"), do: gettext("Pantheon")
  defp name("trevi"), do: gettext("Trevi Fountain")

  defp lng_lat([lng, lat]), do: "#{lng}, #{lat}"
end
