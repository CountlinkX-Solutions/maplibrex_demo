defmodule MaplibrexDemoWeb.TilesLive do
  @moduledoc """
  Vector tiles served by a separate tile server.

  Unlike the other demos, this page depends on something outside the demo
  application: the sibling `tileserver` project, configured via
  `:tile_server_url` (override with `TILE_SERVER_URL`). The server is probed on
  mount; when it is not reachable the page falls back to a public basemap and
  says so, rather than rendering a blank map with no explanation.
  """
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}

  import MaplibreX.Components

  @center [-74.5, 40]
  @zoom 2

  @probe_timeout_ms 2_000

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:server_url, server_url())
      |> assign(:server_status, :checking)
      |> assign(:current_style, "default")
      |> assign(:center, @center)
      |> assign(:zoom, @zoom)
      |> assign(:current_center, @center)
      |> assign(:current_zoom, @zoom)
      |> assign(:available_styles, [
        %{
          id: "default",
          name: "Default",
          description: gettext("Auto-generated with all sources")
        },
        %{id: "dark", name: "Dark", description: gettext("Dark theme with glow effects")},
        %{id: "light", name: "Light", description: gettext("Minimal light theme")},
        %{
          id: "advanced",
          name: "Advanced",
          description: gettext("With expressions and advanced styles")
        }
      ])
      |> assign(:vector_layers, ~w(cities countries demo world))

    if connected?(socket), do: send(self(), :probe_server)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.demo_page
      path={~p"/tiles"}
      locale={@locale}
      title={gettext("Vector Tiles Server")}
      subtitle={gettext("Live tile rendering from a self-hosted vector tile server")}
    >
      <:map>
        <%!-- The style URL is an assign, so switching styles (or falling back
              to the public basemap) is a plain LiveView state change. --%>
        <.map
          id="tiles-map"
          center={@center}
          zoom={@zoom}
          style={style_url(assigns)}
          class="absolute inset-0 h-full w-full"
        />

        <.navigation_control id="nav-control" map_id="tiles-map" position="top-left" />
        <.scale_control id="scale-control" map_id="tiles-map" position="bottom-left" unit="metric" />
        <.fullscreen_control id="fullscreen-control" map_id="tiles-map" position="top-left" />
      </:map>

      <:panel>
        <.panel_section label={gettext("Tile Server")}>
          <.service_status
            status={@server_status}
            url={@server_url}
            hint={
              gettext(
                "Showing a public basemap instead. Start the tile server, or point this demo elsewhere with TILE_SERVER_URL."
              )
            }
          />
        </.panel_section>

        <.panel_section label={gettext("Style")} class="space-y-1">
          <.option_button
            :for={style <- @available_styles}
            active={@current_style == style.id}
            description={style.description}
            phx-click="change_style"
            phx-value-id={style.id}
          >
            {style.name}
          </.option_button>
        </.panel_section>

        <.panel_section label={gettext("Vector Layers")} class="flex flex-wrap gap-1.5">
          <.chip :for={layer <- @vector_layers}>{layer}</.chip>
        </.panel_section>

        <.panel_section :if={@server_status == :ok} label={gettext("Server Links")} class="space-y-1">
          <.link_row href={"#{@server_url}/styles/#{@current_style}.json"}>
            {gettext("Style JSON")}
          </.link_row>
          <.link_row :for={layer <- ~w(cities countries)} href={"#{@server_url}/#{layer}.json"}>
            TileJSON: {layer}
          </.link_row>
        </.panel_section>
      </:panel>

      <:telemetry>
        <.stat first label={gettext("Center")} value={format_center(@current_center)} />
        <.stat label={gettext("Zoom")} value={Float.round(@current_zoom * 1.0, 1)} />
        <.stat label={gettext("Style")} value={@current_style} class="font-mono text-xs capitalize" />
        <.stat label={gettext("Source")} value={source_label(@server_status)} />
      </:telemetry>
    </.demo_page>
    """
  end

  @impl true
  def handle_info(:probe_server, socket) do
    {:noreply, assign(socket, :server_status, probe(socket.assigns.server_url))}
  end

  @impl true
  def handle_event("change_style", %{"id" => style_id}, socket) do
    {:noreply, assign(socket, :current_style, style_id)}
  end

  def handle_event("map:moved", %{"center" => center, "zoom" => zoom}, socket) do
    {:noreply, socket |> assign(:current_center, center) |> assign(:current_zoom, zoom)}
  end

  def handle_event("map:zoom_changed", %{"zoom" => zoom}, socket) do
    {:noreply, assign(socket, :current_zoom, zoom)}
  end

  def handle_event("map:" <> _, _params, socket), do: {:noreply, socket}

  # Serve the requested style from the tile server, or the public fallback when
  # it is not reachable. While probing, use the fallback so the map is never
  # blank.
  defp style_url(%{server_status: :ok, server_url: url, current_style: style}),
    do: "#{url}/styles/#{style}.json"

  defp style_url(_assigns),
    do: Application.get_env(:maplibrex_demo, :fallback_style_url)

  defp source_label(:ok), do: gettext("tile server")
  defp source_label(_), do: gettext("fallback")

  defp server_url, do: Application.get_env(:maplibrex_demo, :tile_server_url)

  defp probe(url) do
    case Req.get("#{url}/styles/default.json",
           receive_timeout: @probe_timeout_ms,
           retry: false
         ) do
      {:ok, %{status: 200}} -> :ok
      _ -> :unreachable
    end
  rescue
    _ -> :unreachable
  end

  defp format_center([lng, lat]) do
    "#{Float.round(lng * 1.0, 3)}, #{Float.round(lat * 1.0, 3)}"
  end
end
