defmodule MaplibrexDemoWeb.TerrainLive do
  @moduledoc """
  3D terrain from a raster-DEM source, with a hillshade layer underneath and a
  live exaggeration control.

  The terrain component is reactive: changing `@exaggeration` re-applies the
  terrain without remounting the map.
  """
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}

  import MaplibreX.Components
  alias MaplibreX.Components.Map, as: MapCmd

  # Same camera as the official MapLibre 3D terrain example.
  @alps [11.39085, 47.27574]
  @zoom 12
  @pitch 70

  @dem_url "https://tiles.mapterhorn.com/tilejson.json"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:terrain_enabled, true)
      |> assign(:exaggeration, 1.0)
      |> assign(:center, @alps)
      |> assign(:zoom, @zoom)
      |> assign(:current_zoom, @zoom)
      |> assign(:current_pitch, @pitch)
      |> assign(:current_bearing, 0)
      |> assign(:dem_url, @dem_url)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.demo_page
      path={~p"/terrain"}
      locale={@locale}
      title={gettext("3D Terrain")}
      subtitle={gettext("Elevation rendering with DEM sources")}
    >
      <:map>
        <%!-- max_pitch is not decoration: MapLibre clamps pitch to 60 without
              it, which flattens this view. Same camera as the official
              MapLibre 3D terrain example. --%>
        <.map
          id="terrain-map"
          center={@center}
          zoom={@zoom}
          pitch={70}
          bearing={0}
          max_zoom={18}
          max_pitch={85}
          style="https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json"
          class="absolute inset-0 h-full w-full"
        />

        <.navigation_control id="nav-control" map_id="terrain-map" position="top-left" />

        <%!-- Terrain and hillshade each need their own source: MapLibre will
              not let one raster-dem source back both at the same time. --%>
        <.raster_dem_source id="terrain-source" map_id="terrain-map" url={@dem_url} />
        <.raster_dem_source id="hillshade-source" map_id="terrain-map" url={@dem_url} />

        <.hillshade_layer
          id="hillshade"
          map_id="terrain-map"
          source_id="hillshade-source"
          paint={
            %{
              "hillshade-exaggeration" => 0.7,
              "hillshade-shadow-color" => "#473B24",
              "hillshade-highlight-color" => "#ffffff",
              "hillshade-illumination-anchor" => "map"
            }
          }
        />

        <.terrain
          :if={@terrain_enabled}
          map_id="terrain-map"
          source_id="terrain-source"
          exaggeration={@exaggeration}
        />
      </:map>

      <:panel>
        <.panel_section label={gettext("Terrain")}>
          <.toggle_button
            active={@terrain_enabled}
            on_label={gettext("Enabled")}
            off_label={gettext("Disabled")}
            phx-click="toggle_terrain"
          >
            {gettext("3D Terrain")}
          </.toggle_button>
        </.panel_section>

        <.panel_section label={gettext("Exaggeration")}>
          <.slider
            label={gettext("Vertical scale")}
            name="value"
            value={@exaggeration}
            min="0.5"
            max="3.0"
            step="0.1"
            on_change="update_exaggeration"
            display={"#{Float.round(@exaggeration * 1.0, 1)}x"}
          />
          <div class="mt-1 flex justify-between text-[10px] text-white/25">
            <span>0.5x</span>
            <span>3.0x</span>
          </div>
        </.panel_section>

        <.panel_section label={gettext("Location")} class="flex gap-2">
          <.action_button phx-click={
            MapCmd.fly_to("terrain-map", @center, 12, duration: 1500, pitch: 70, bearing: 0)
          }>
            Alps
          </.action_button>
          <.action_button phx-click={
            MapCmd.fly_to("terrain-map", [7.6586, 45.9763], 13,
              duration: 1500,
              pitch: 72,
              bearing: 0
            )
          }>
            Matterhorn
          </.action_button>
        </.panel_section>
      </:panel>

      <:telemetry>
        <.stat first label={gettext("Pitch")} value={"#{round(@current_pitch)}°"} />
        <.stat label={gettext("Bearing")} value={"#{round(@current_bearing)}°"} />
        <.stat label={gettext("Zoom")} value={Float.round(@current_zoom * 1.0, 1)} />
        <.stat label={gettext("Exaggeration")} value={"#{Float.round(@exaggeration * 1.0, 1)}x"} />
      </:telemetry>
    </.demo_page>
    """
  end

  @impl true
  def handle_event("toggle_terrain", _params, socket) do
    {:noreply, assign(socket, :terrain_enabled, !socket.assigns.terrain_enabled)}
  end

  def handle_event("update_exaggeration", %{"value" => value}, socket) do
    {:noreply, assign(socket, :exaggeration, parse_float(value, 1.0))}
  end

  def handle_event("map:moved", params, socket) do
    socket =
      socket
      |> assign(:current_zoom, params["zoom"] || socket.assigns.current_zoom)
      |> assign(:current_pitch, params["pitch"] || socket.assigns.current_pitch)
      |> assign(:current_bearing, params["bearing"] || socket.assigns.current_bearing)

    {:noreply, socket}
  end

  def handle_event("map:zoom_changed", %{"zoom" => zoom}, socket) do
    {:noreply, assign(socket, :current_zoom, zoom)}
  end

  # Lifecycle events the demo acknowledges but does not act on.
  def handle_event("map:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("source:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("terrain:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("layer:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("sky:" <> _, _params, socket), do: {:noreply, socket}

  defp parse_float(value, fallback) do
    case Float.parse(value) do
      {parsed, _} -> parsed
      :error -> fallback
    end
  end
end
