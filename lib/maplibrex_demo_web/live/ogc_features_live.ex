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
    <div class="relative h-screen w-full">
      <%!-- Mapa --%>
      <.map
        id="ogc-map"
        center={[0, 20]}
        zoom={2}
        style="https://demotiles.maplibre.org/style.json"
        class="absolute top-0 left-0 w-full h-full"
      />

      <.navigation_control
        id="nav-control"
        map_id="ogc-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- Panel Lateral --%>
      <div class="absolute top-2 right-2 bg-white rounded-lg shadow-xl max-w-md max-h-[90vh] overflow-y-auto z-10">
        <div class="p-5">
          <h2 class="text-xl font-bold mb-3 pb-2 border-b-2 border-blue-500 text-gray-800">
            🧪 OGC Features Test
          </h2>

          <%!-- Info Box --%>
          <div class="bg-yellow-50 border border-yellow-400 p-3 rounded-md mb-4 text-sm text-yellow-900">
            <strong class="block mb-1">Test Purpose:</strong>
            Verify that the server sends coordinates in the correct order [lon, lat] and that they display correctly on the map.
          </div>

          <%!-- Status --%>
          <%= if @loading do %>
            <div class="bg-blue-50 text-blue-900 p-3 rounded-md mb-4 text-sm">
              Loading features...
            </div>
          <% end %>

          <%= if @error do %>
            <div class="bg-red-50 text-red-900 p-3 rounded-md mb-4 text-sm">
              ❌ Error: <%= @error %>
            </div>
          <% end %>

          <%= if !@loading and is_nil(@error) do %>
            <div class="bg-green-50 text-green-900 p-3 rounded-md mb-4 text-sm">
              ✅ Loaded <%= @feature_count %> features<br />
              <span class="text-xs">Check if cities appear in correct locations!</span>
            </div>
          <% end %>

          <%!-- Test Cities --%>
          <%= if length(@test_cities) > 0 do %>
            <h3 class="text-sm font-semibold text-gray-600 mt-4 mb-2">Test Cities:</h3>
            <%= for city <- @test_cities do %>
              <div class={"p-2 rounded mb-2 text-sm border-l-4 #{if city.correct, do: "bg-gray-50 border-green-500", else: "bg-red-50 border-red-500"}"}>
                <strong class="text-gray-900">
                  <%= if city.correct, do: "✅", else: "❌" %> <%= city.name %>
                </strong>
                <div class="text-blue-600 font-mono text-xs mt-1">
                  Server: [<%= Float.round(Enum.at(city.coords, 0), 2) %>, <%= Float.round(Enum.at(city.coords, 1), 2) %>]
                </div>
                <div class="text-gray-600 text-xs italic mt-1">
                  Expected: [<%= Float.round(city.expected.lon, 2) %>, <%= Float.round(city.expected.lat, 2) %>]<br />
                  Location: <%= city.expected.region %>
                </div>
              </div>
            <% end %>
          <% end %>

          <%!-- Buttons --%>
          <div class="space-y-2 mt-4">
            <button
              phx-click="reload_features"
              class="w-full bg-blue-500 text-white py-2 px-4 rounded-md hover:bg-blue-600 font-medium"
            >
              🔄 Reload Features
            </button>
            <button
              phx-click="fly_to_city"
              phx-value-city="Tokyo"
              class="w-full bg-blue-500 text-white py-2 px-4 rounded-md hover:bg-blue-600 font-medium"
            >
              📍 Fly to Tokyo
            </button>
            <button
              phx-click="fly_to_city"
              phx-value-city="New York"
              class="w-full bg-blue-500 text-white py-2 px-4 rounded-md hover:bg-blue-600 font-medium"
            >
              📍 Fly to New York
            </button>
          </div>
        </div>
      </div>

      <%!-- GeoJSON Layer for Features --%>
      <%= if length(@features) > 0 do %>
        <.geojson_layer
          id="cities-layer"
          map_id="ogc-map"
          data={%{type: "FeatureCollection", features: @features}}
          type="circle"
          paint={%{
            "circle-radius" => 8,
            "circle-color" => "#3b82f6",
            "circle-stroke-width" => 2,
            "circle-stroke-color" => "#ffffff"
          }}
        />
      <% end %>
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
