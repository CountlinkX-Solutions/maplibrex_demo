defmodule MaplibrexDemoWeb.OgcFeaturesLive do
  @moduledoc """
  Reads city features from an OGC API - Features endpoint and renders each one
  as a marker.

  Like `/tiles`, this page depends on the sibling `tileserver` project via
  `:tile_server_url` (override with `TILE_SERVER_URL`). When the endpoint is
  not reachable the page says so and offers a retry, instead of sitting on an
  empty map.

  It also spot-checks a handful of well-known cities: if the server returns
  coordinates more than a degree away from the expected position, the axis
  order is probably swapped — a common OGC implementation bug.
  """
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}

  import MaplibreX.Components
  alias MaplibreX.Components.Map, as: MapCmd

  @center [0, 20]
  @zoom 2

  @request_timeout_ms 5_000
  @feature_limit 50

  # Reference coordinates used to sanity-check what the server returns.
  @expected_coords %{
    "Tokyo" => %{lon: 139.74, lat: 35.68, region: "Asia (East)"},
    "New York" => %{lon: -73.99, lat: 40.72, region: "North America"},
    "Madrid" => %{lon: -3.70, lat: 40.41, region: "Europe"},
    "Mexico City" => %{lon: -99.13, lat: 19.44, region: "North America"},
    "London" => %{lon: -0.12, lat: 51.50, region: "Europe"}
  }

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:server_url, server_url())
      |> assign(:status, :checking)
      |> assign(:error, nil)
      |> assign(:features, [])
      |> assign(:test_cities, [])
      |> assign(:feature_count, 0)
      |> assign(:center, @center)
      |> assign(:zoom, @zoom)
      |> assign(:current_center, @center)
      |> assign(:current_zoom, @zoom)

    if connected?(socket), do: send(self(), :load_features)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.demo_page
      path={~p"/ogc"}
      locale={@locale}
      title={gettext("OGC Features")}
      subtitle={gettext("OGC API Features conformance test against a self-hosted server")}
    >
      <:map>
        <.map
          id="ogc-map"
          center={@center}
          zoom={@zoom}
          style="https://demotiles.maplibre.org/style.json"
          class="absolute inset-0 h-full w-full"
        />

        <.navigation_control id="nav-control" map_id="ogc-map" position="top-left" />

        <.marker
          :for={feature <- @features}
          id={"city-#{:erlang.phash2(feature["properties"]["name"])}"}
          map_id="ogc-map"
          lng_lat={feature["geometry"]["coordinates"]}
          color="#3b82f6"
          draggable={false}
          popup_text={feature["properties"]["name"]}
        />
      </:map>

      <:panel>
        <.panel_section label={gettext("Feature Server")}>
          <.service_status
            status={@status}
            url={"#{@server_url}/ogc/collections/cities/items"}
            hint={
              gettext("Start the tile server, or point this demo elsewhere with TILE_SERVER_URL.")
            }
          />
          <p :if={@error} class="mt-2 font-mono text-[10px] break-all text-amber-200/70">
            {@error}
          </p>
        </.panel_section>

        <.panel_section label={gettext("Actions")} class="space-y-1.5">
          <.option_button phx-click="reload_features">
            {gettext("Reload Features")}
          </.option_button>
          <.option_button phx-click={MapCmd.fly_to("ogc-map", [139.74, 35.68], 10, duration: 1200)}>
            {gettext("Fly to Tokyo")}
          </.option_button>
          <.option_button phx-click={MapCmd.fly_to("ogc-map", [-73.99, 40.72], 10, duration: 1200)}>
            {gettext("Fly to New York")}
          </.option_button>
        </.panel_section>

        <.panel_section :if={@test_cities != []} label={gettext("Test Results")} class="space-y-2">
          <div
            :for={city <- @test_cities}
            class="space-y-1.5 rounded-xl border border-white/[0.07] bg-white/[0.04] p-3"
          >
            <div class="flex items-center justify-between">
              <span class="text-xs font-medium text-white/80">{city.name}</span>
              <span class={[
                "inline-flex items-center rounded-full border px-2 py-0.5 text-[9px] font-semibold",
                if(city.correct,
                  do: "border-emerald-400/25 bg-emerald-500/10 text-emerald-300",
                  else: "border-red-400/25 bg-red-500/10 text-red-300"
                )
              ]}>
                {if city.correct, do: gettext("Pass"), else: gettext("Fail")}
              </span>
            </div>

            <div class="flex gap-3 text-[9px]">
              <div>
                <p class="tracking-widest text-white/30 uppercase">{gettext("Server")}</p>
                <p class="font-mono text-white/55">
                  [{Float.round(Enum.at(city.coords, 0) * 1.0, 2)}, {Float.round(
                    Enum.at(city.coords, 1) * 1.0,
                    2
                  )}]
                </p>
              </div>
              <div class="w-px bg-white/10" />
              <div>
                <p class="tracking-widest text-white/30 uppercase">{gettext("Region")}</p>
                <p class="font-mono text-white/55">{city.expected.region}</p>
              </div>
            </div>

            <.action_button phx-click={MapCmd.fly_to("ogc-map", city.coords, 10, duration: 1200)}>
              {gettext("Fly to %{city}", city: city.name)}
            </.action_button>
          </div>
        </.panel_section>
      </:panel>

      <:telemetry>
        <.stat first label={gettext("Features")} value={@feature_count} />
        <.stat label={gettext("Status")} value={status_label(@status)} />
        <.stat label={gettext("Center")} value={format_center(@current_center)} />
      </:telemetry>
    </.demo_page>
    """
  end

  @impl true
  def handle_info(:load_features, socket) do
    socket =
      case fetch_features(socket.assigns.server_url) do
        {:ok, features} ->
          socket
          |> assign(:status, :ok)
          |> assign(:error, nil)
          |> assign(:features, features)
          |> assign(:feature_count, length(features))
          |> assign(:test_cities, extract_test_cities(features))

        {:error, reason} ->
          socket
          |> assign(:status, :unreachable)
          |> assign(:error, reason)
          |> assign(:features, [])
          |> assign(:feature_count, 0)
          |> assign(:test_cities, [])
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("reload_features", _params, socket) do
    send(self(), :load_features)
    {:noreply, socket |> assign(:status, :checking) |> assign(:error, nil)}
  end

  def handle_event("map:moved", %{"center" => center, "zoom" => zoom}, socket) do
    {:noreply, socket |> assign(:current_center, center) |> assign(:current_zoom, zoom)}
  end

  def handle_event("map:zoom_changed", %{"zoom" => zoom}, socket) do
    {:noreply, assign(socket, :current_zoom, zoom)}
  end

  def handle_event("map:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("marker:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("layer:" <> _, _params, socket), do: {:noreply, socket}

  defp server_url, do: Application.get_env(:maplibrex_demo, :tile_server_url)

  defp status_label(:ok), do: gettext("ready")
  defp status_label(:checking), do: gettext("loading")
  defp status_label(_), do: gettext("error")

  defp fetch_features(server_url) do
    url = "#{server_url}/ogc/collections/cities/items?limit=#{@feature_limit}"

    case Req.get(url, receive_timeout: @request_timeout_ms, retry: false) do
      {:ok, %{status: 200, body: body}} -> {:ok, body["features"] || []}
      {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, Exception.message(reason)}
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  # Flags features whose coordinates land more than a degree from where the
  # city actually is — usually a lat/lon axis-order bug on the server.
  defp extract_test_cities(features) do
    features
    |> Enum.filter(&Map.has_key?(@expected_coords, get_in(&1, ["properties", "name"])))
    |> Enum.take(5)
    |> Enum.map(fn feature ->
      name = get_in(feature, ["properties", "name"])
      [lon, lat] = coords = get_in(feature, ["geometry", "coordinates"])
      expected = Map.fetch!(@expected_coords, name)

      %{
        name: name,
        coords: coords,
        expected: expected,
        correct: abs(lon - expected.lon) < 1 and abs(lat - expected.lat) < 1
      }
    end)
  end

  defp format_center([lng, lat]) do
    "#{Float.round(lng * 1.0, 2)}, #{Float.round(lat * 1.0, 2)}"
  end
end
