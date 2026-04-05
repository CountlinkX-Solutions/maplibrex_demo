defmodule MaplibrexDemoWeb.OgcFeaturesLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components

  @server_url "http://localhost:4000"

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
      |> assign(:server_url, @server_url)
      |> assign(:loading, true)
      |> assign(:error, nil)
      |> assign(:features, [])
      |> assign(:test_cities, [])
      |> assign(:feature_count, 0)
      |> assign(:current_center, [0, 20])
      |> assign(:current_zoom, 2)

    # Load features on mount
    send(self(), :load_features)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-full h-screen overflow-hidden bg-[#050810]">
      <%!-- Map full-screen --%>
      <.map
        id="ogc-map"
        center={[0, 20]}
        zoom={2}
        style="https://demotiles.maplibre.org/style.json"
        class="absolute inset-0 w-full h-full"
      />

      <%!-- Navigation Control --%>
      <.navigation_control
        id="nav-control"
        map_id="ogc-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- Markers con popup por cada feature cargada --%>
      <%= for feature <- @features do %>
        <.marker
          id={"city-#{:erlang.phash2(feature["properties"]["name"])}"}
          map_id="ogc-map"
          lng_lat={feature["geometry"]["coordinates"]}
          color="#3b82f6"
          draggable={false}
          popup_text={feature["properties"]["name"]}
        />
      <% end %>

      <%!-- Back nav pill --%>
      <div class="absolute top-[110px] left-4 z-20">
        <a
          href="/"
          class="flex items-center gap-2 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-4 py-2 text-sm text-white/70 hover:text-white transition-all duration-300 no-underline"
        >
          &larr; Demos
        </a>
      </div>

      <%!-- Control Panel --%>
      <div class="absolute top-4 right-4 bottom-16 w-72 z-20 overflow-y-auto">
        <div class="bg-[rgba(8,12,28,0.85)] backdrop-blur-xl border border-white/[0.09] rounded-2xl p-5 space-y-5">
          <%!-- Header --%>
          <div>
            <h2 class="text-sm font-semibold text-white tracking-wide">OGC Features</h2>
            <p class="text-[11px] text-white/40 mt-0.5 leading-relaxed">
              OGC API Features conformance test against localhost:4000
            </p>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Status --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              Status
            </p>
            <%= if @loading do %>
              <div class="flex items-center gap-2 text-sm text-white/60">
                <div class="w-3 h-3 rounded-full border border-cyan-400/50 border-t-cyan-400 animate-spin">
                </div>
                Loading features...
              </div>
            <% end %>
            <%= if @error do %>
              <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[9px] font-semibold bg-red-500/10 border border-red-400/25 text-red-300">
                Error: {@error}
              </span>
            <% end %>
            <%= if !@loading and is_nil(@error) do %>
              <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[9px] font-semibold bg-emerald-500/10 border border-emerald-400/25 text-emerald-300">
                {@feature_count} features loaded
              </span>
            <% end %>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Actions --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              Actions
            </p>
            <div class="space-y-1.5">
              <button
                phx-click="reload_features"
                class="w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300"
              >
                Reload Features
              </button>
              <button
                onclick="document.getElementById('ogc-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [139.74, 35.68], zoom: 10, duration: 1200}}))"
                class="w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300"
              >
                Fly to Tokyo
              </button>
              <button
                onclick="document.getElementById('ogc-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [-73.99, 40.72], zoom: 10, duration: 1200}}))"
                class="w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300"
              >
                Fly to New York
              </button>
            </div>
          </div>

          <%!-- Test Results --%>
          <%= if length(@test_cities) > 0 do %>
            <div class="h-px bg-white/[0.06]"></div>
            <div>
              <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
                Test Results
              </p>
              <div class="space-y-2">
                <%= for city <- @test_cities do %>
                  <div class="bg-white/[0.04] border border-white/[0.07] rounded-xl p-3 space-y-1.5">
                    <div class="flex items-center justify-between">
                      <span class="text-xs text-white/80 font-medium">{city.name}</span>
                      <%= if city.correct do %>
                        <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[9px] font-semibold bg-emerald-500/10 border border-emerald-400/25 text-emerald-300">
                          Pass
                        </span>
                      <% else %>
                        <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[9px] font-semibold bg-red-500/10 border border-red-400/25 text-red-300">
                          Fail
                        </span>
                      <% end %>
                    </div>
                    <div class="flex gap-3 text-[9px]">
                      <div>
                        <p class="text-white/30 uppercase tracking-widest">Server</p>
                        <p class="font-mono text-white/55">
                          [{Float.round(Enum.at(city.coords, 0), 2)}, {Float.round(
                            Enum.at(city.coords, 1),
                            2
                          )}]
                        </p>
                      </div>
                      <div class="w-px bg-white/10"></div>
                      <div>
                        <p class="text-white/30 uppercase tracking-widest">Region</p>
                        <p class="font-mono text-white/55">{city.expected.region}</p>
                      </div>
                    </div>
                    <button
                      onclick={"document.getElementById('ogc-map').dispatchEvent(new CustomEvent('maplibrex:fly_to', {detail: {center: [#{Enum.at(city.coords, 0)}, #{Enum.at(city.coords, 1)}], zoom: 10, duration: 1200}}))"}
                      class="w-full text-left px-2 py-1.5 rounded-lg text-[10px] text-white/50 hover:text-white/80 bg-white/[0.03] hover:bg-white/[0.07] border border-white/[0.05] hover:border-white/[0.10] transition-all duration-300"
                    >
                      Fly to {city.name}
                    </button>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Server --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              Server
            </p>
            <p class="font-mono text-[10px] text-white/50 break-all">{@server_url}</p>
          </div>
        </div>
      </div>

      <%!-- Telemetry --%>
      <div class="absolute bottom-4 left-4 z-20">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-xl px-4 py-3 flex items-center gap-4">
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">Features</p>
            <p class="font-mono text-xs text-cyan-300/90">{@feature_count}</p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">Status</p>
            <p class="font-mono text-xs text-cyan-300/90">
              {cond do
                @loading -> "loading"
                @error -> "error"
                true -> "ready"
              end}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info(:load_features, socket) do
    case fetch_features() do
      {:ok, features} ->
        test_cities = extract_test_cities(features)

        socket =
          socket
          |> assign(:loading, false)
          |> assign(:features, features)
          |> assign(:feature_count, length(features))
          |> assign(:test_cities, test_cities)

        {:noreply, socket}

      {:error, reason} ->
        socket =
          socket
          |> assign(:loading, false)
          |> assign(:error, reason)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("reload_features", _params, socket) do
    socket =
      socket
      |> assign(:loading, true)
      |> assign(:error, nil)

    send(self(), :load_features)
    {:noreply, socket}
  end

  @impl true
  def handle_event("fly_to_city", %{"city" => city_name}, socket) do
    case Enum.find(socket.assigns.features, fn f -> f["properties"]["name"] == city_name end) do
      nil ->
        {:noreply, socket}

      feature ->
        coords = feature["geometry"]["coordinates"]

        socket =
          push_event(socket, "map:fly_to", %{
            map_id: "ogc-map",
            center: coords,
            zoom: 10,
            duration: 1500
          })

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("map:moved", %{"center" => center, "zoom" => zoom}, socket) do
    socket =
      socket
      |> assign(:current_center, center)
      |> assign(:current_zoom, zoom)

    {:noreply, socket}
  end

  @impl true
  def handle_event("map:zoom_changed", %{"zoom" => zoom}, socket) do
    {:noreply, assign(socket, :current_zoom, zoom)}
  end

  @impl true
  def handle_event("map:loaded", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:clicked", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:error", %{"error" => error}, socket) do
    IO.inspect(error, label: "Map error")
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:feature_mouseenter", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:feature_mouseleave", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("layer:feature_clicked", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("marker:clicked", _params, socket) do
    {:noreply, socket}
  end

  # Private functions

  defp fetch_features do
    url = "#{@server_url}/ogc/collections/cities/items?limit=50"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body["features"] || []}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp extract_test_cities(features) do
    features
    |> Enum.filter(fn f ->
      name = get_in(f, ["properties", "name"])
      Map.has_key?(@expected_coords, name)
    end)
    |> Enum.take(5)
    |> Enum.map(fn feature ->
      name = get_in(feature, ["properties", "name"])
      coords = get_in(feature, ["geometry", "coordinates"])
      expected = Map.get(@expected_coords, name)

      lon_match = abs(Enum.at(coords, 0) - expected.lon) < 1
      lat_match = abs(Enum.at(coords, 1) - expected.lat) < 1

      %{
        name: name,
        coords: coords,
        expected: expected,
        correct: lon_match and lat_match
      }
    end)
  end
end
