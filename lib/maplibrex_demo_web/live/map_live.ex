defmodule MaplibrexDemoWeb.MapLive do
  @moduledoc """
  The core demo: markers, a GeoJSON layer, reactive style switching and
  client-side map commands.

  Two ways of driving the map are shown side by side:

    * **Reactive** — the style buttons only change an assign. The map follows,
      because `<.map style={@current_style}>` is reactive.
    * **Client-side commands** — the fly-to buttons use
      `MaplibreX.Components.Map.fly_to/4`, which renders a
      `Phoenix.LiveView.JS` command that runs in the browser with no server
      round-trip.
  """
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}

  import MaplibreX.Components
  alias MaplibreX.Components.Map, as: MapCmd

  @initial_center [-74.5, 40]
  @initial_zoom 9

  @marker_colors ~w(red blue green purple orange yellow pink)

  @demo_geojson %{
    type: "FeatureCollection",
    features: [
      %{
        type: "Feature",
        properties: %{name: "NYC Area", description: "Demo GeoJSON Layer"},
        geometry: %{
          type: "Polygon",
          coordinates: [
            [[-74.25, 40.9], [-73.7, 40.9], [-73.7, 40.5], [-74.25, 40.5], [-74.25, 40.9]]
          ]
        }
      }
    ]
  }

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:center, @initial_center)
      |> assign(:zoom, @initial_zoom)
      |> assign(:current_center, @initial_center)
      |> assign(:current_zoom, @initial_zoom)
      |> assign(:current_style, "https://demotiles.maplibre.org/style.json")
      |> assign(:show_geojson, true)
      |> assign(:show_popups, true)
      |> assign(:demo_geojson, @demo_geojson)
      |> assign(:markers, [
        %{id: "marker-1", lng_lat: [-74.5, 40], color: "red", draggable: false},
        %{id: "marker-2", lng_lat: [-74.0, 40.5], color: "blue", draggable: true},
        %{id: "marker-3", lng_lat: [-73.5, 40.2], color: "green", draggable: false}
      ])
      |> assign(:map_styles, [
        %{name: "OpenStreetMap", url: "https://demotiles.maplibre.org/style.json"},
        %{name: "Dark", url: "https://tiles.openfreemap.org/styles/dark"},
        %{name: "Liberty", url: "https://tiles.openfreemap.org/styles/liberty"}
      ])

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.demo_page
      path={~p"/map"}
      locale={@locale}
      title={gettext("Interactive Map")}
      subtitle={gettext("Markers, GeoJSON layers, real-time events")}
    >
      <:map>
        <.map
          id="demo-map"
          center={@center}
          zoom={@zoom}
          style={@current_style}
          class="absolute inset-0 h-full w-full"
        />

        <.navigation_control id="nav-control" map_id="demo-map" position="top-left" />
        <.scale_control id="scale-control" map_id="demo-map" position="bottom-left" unit="metric" />
        <.fullscreen_control id="fullscreen-control" map_id="demo-map" position="top-left" />

        <.geojson_layer
          :if={@show_geojson}
          id="nyc-area"
          map_id="demo-map"
          data={@demo_geojson}
          type="fill"
          paint={
            %{
              "fill-color" => "#22d3ee",
              "fill-opacity" => 0.25,
              "fill-outline-color" => "#22d3ee"
            }
          }
        />

        <.marker
          :for={marker <- @markers}
          id={marker.id}
          map_id="demo-map"
          lng_lat={marker.lng_lat}
          color={marker.color}
          draggable={marker.draggable}
          popup_text={if @show_popups, do: "#{marker.id} — #{marker.color}"}
        />
      </:map>

      <:panel>
        <.panel_section label={gettext("Map Style")} class="space-y-1">
          <.option_button
            :for={style <- @map_styles}
            active={@current_style == style.url}
            phx-click="update_style"
            phx-value-url={style.url}
          >
            {style.name}
          </.option_button>
        </.panel_section>

        <.panel_section label={gettext("Navigation")} class="flex gap-2">
          <.action_button phx-click={MapCmd.fly_to("demo-map", [-73.98, 40.75], 12)}>
            NYC
          </.action_button>
          <.action_button phx-click={MapCmd.fly_to("demo-map", [-118.24, 34.05], 12, duration: 1500)}>
            Los Angeles
          </.action_button>
          <.action_button phx-click={MapCmd.fly_to("demo-map", @center, @zoom, duration: 1500)}>
            {gettext("Reset")}
          </.action_button>
        </.panel_section>

        <.panel_section label={gettext("Layers")}>
          <.toggle_button
            active={@show_geojson}
            on_label={gettext("Visible")}
            off_label={gettext("Hidden")}
            phx-click="toggle_geojson"
          >
            {gettext("GeoJSON Layer")}
          </.toggle_button>
        </.panel_section>

        <.panel_section label={gettext("Markers")} class="flex gap-2">
          <.action_button phx-click="add_marker">{gettext("Add Marker")}</.action_button>
          <.action_button phx-click="clear_markers">{gettext("Clear All")}</.action_button>
        </.panel_section>
      </:panel>

      <:telemetry>
        <.stat first label={gettext("Center")} value={format_center(@current_center)} />
        <.stat label={gettext("Zoom")} value={format_zoom(@current_zoom)} />
        <.stat label={gettext("Markers")} value={length(@markers)} />
      </:telemetry>
    </.demo_page>
    """
  end

  @impl true
  def handle_event("update_style", %{"url" => url}, socket) do
    # No JS command needed: `<.map style={@current_style}>` is reactive, so
    # updating the assign is enough for the hook to call setStyle.
    {:noreply, assign(socket, :current_style, url)}
  end

  def handle_event("toggle_geojson", _params, socket) do
    {:noreply, assign(socket, :show_geojson, !socket.assigns.show_geojson)}
  end

  def handle_event("toggle_popups", _params, socket) do
    {:noreply, assign(socket, :show_popups, !socket.assigns.show_popups)}
  end

  def handle_event("add_marker", _params, socket) do
    [lng, lat] = socket.assigns.current_center
    new_lng = lng + (:rand.uniform() - 0.5) * 2
    new_lat = lat + (:rand.uniform() - 0.5) * 2

    marker = %{
      id: "marker-#{System.unique_integer([:positive])}",
      lng_lat: [new_lng, new_lat],
      color: Enum.random(@marker_colors),
      draggable: true
    }

    socket =
      socket
      |> update(:markers, &(&1 ++ [marker]))
      # The server-side counterpart of MapCmd.fly_to/4: MaplibreX listens for
      # this event name on every mounted map.
      |> push_event("map:fly_to", %{center: marker.lng_lat, zoom: 13, duration: 1000})

    {:noreply, socket}
  end

  def handle_event("clear_markers", _params, socket) do
    {:noreply, assign(socket, :markers, [])}
  end

  # Map events pushed by MaplibreX. `map:moved` is debounced client-side, so
  # these assigns update without flooding the socket during a pan.
  def handle_event("map:moved", %{"center" => center, "zoom" => zoom}, socket) do
    {:noreply, socket |> assign(:current_center, center) |> assign(:current_zoom, zoom)}
  end

  def handle_event("map:zoom_changed", %{"zoom" => zoom}, socket) do
    {:noreply, assign(socket, :current_zoom, zoom)}
  end

  def handle_event("marker:drag_end", %{"markerId" => id, "lngLat" => lng_lat}, socket) do
    markers =
      Enum.map(socket.assigns.markers, fn
        %{id: ^id} = marker -> %{marker | lng_lat: lng_lat}
        marker -> marker
      end)

    {:noreply, assign(socket, :markers, markers)}
  end

  # Events the demo acknowledges but does not act on.
  def handle_event("map:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("marker:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("layer:" <> _, _params, socket), do: {:noreply, socket}

  defp format_center([lng, lat]) do
    "#{Float.round(lng * 1.0, 3)}, #{Float.round(lat * 1.0, 3)}"
  end

  defp format_zoom(zoom), do: Float.round(zoom * 1.0, 1)
end
