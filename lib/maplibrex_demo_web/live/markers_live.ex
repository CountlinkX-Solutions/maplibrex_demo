defmodule MaplibrexDemoWeb.MarkersLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:markers, generate_initial_markers())
      |> assign(:draggable_marker, [-73.985, 40.758])
      |> assign(:filter_category, "all")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative h-screen w-full">
      <%!-- Mapa base --%>
      <.map
        id="markers-map"
        center={[-73.985, 40.758]}
        zoom={12}
        pitch={0}
        bearing={0}
        style="https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json"
        class="absolute top-0 left-0 w-full h-full"
      />

      <%!-- Navigation Control --%>
      <.navigation_control
        id="nav-control"
        map_id="markers-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
      />

      <%!-- Draggable Marker --%>
      <.marker
        id="draggable-marker"
        map_id="markers-map"
        lng_lat={@draggable_marker}
        color="#FF6B6B"
        scale={1.3}
        draggable={true}
        popup_text="Drag me around! 🎯"
      />

      <%!-- Static Markers (filtrados) --%>
      <%= for marker <- filtered_markers(assigns) do %>
        <.marker
          id={marker.id}
          map_id="markers-map"
          lng_lat={marker.position}
          color={marker.color}
          scale={1.0}
          popup_html={marker.popup_html}
        />
      <% end %>

      <%!-- Panel de Control --%>
      <div class="absolute top-4 right-4 bg-white rounded-lg shadow-2xl p-6 max-w-sm z-10">
        <h2 class="text-2xl font-bold mb-4 border-b border-gray-300 pb-2">
          📍 Interactive Markers
        </h2>

        <%!-- Draggable Marker Info --%>
        <div class="mb-4 p-3 bg-red-50 rounded border border-red-200">
          <h3 class="font-semibold text-sm text-red-900 mb-2">Draggable Marker:</h3>
          <p class="text-xs text-red-800">
            Lng: <%= Float.round(Enum.at(@draggable_marker, 0), 4) %>
          </p>
          <p class="text-xs text-red-800">
            Lat: <%= Float.round(Enum.at(@draggable_marker, 1), 4) %>
          </p>
        </div>

        <%!-- Category Filter --%>
        <div class="mb-4">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Filter by Category:
          </label>
          <div class="space-y-2">
            <button
              phx-click="set_filter"
              phx-value-category="all"
              class={[
                "w-full px-4 py-2 rounded-lg text-sm font-medium transition-all",
                if(@filter_category == "all",
                  do: "bg-blue-500 text-white",
                  else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                )
              ]}
            >
              All (<%= length(@markers) %>)
            </button>
            <button
              phx-click="set_filter"
              phx-value-category="restaurant"
              class={[
                "w-full px-4 py-2 rounded-lg text-sm font-medium transition-all",
                if(@filter_category == "restaurant",
                  do: "bg-orange-500 text-white",
                  else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                )
              ]}
            >
              🍽️ Restaurants (<%= count_by_category(@markers, "restaurant") %>)
            </button>
            <button
              phx-click="set_filter"
              phx-value-category="park"
              class={[
                "w-full px-4 py-2 rounded-lg text-sm font-medium transition-all",
                if(@filter_category == "park",
                  do: "bg-green-500 text-white",
                  else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                )
              ]}
            >
              🌳 Parks (<%= count_by_category(@markers, "park") %>)
            </button>
            <button
              phx-click="set_filter"
              phx-value-category="museum"
              class={[
                "w-full px-4 py-2 rounded-lg text-sm font-medium transition-all",
                if(@filter_category == "museum",
                  do: "bg-purple-500 text-white",
                  else: "bg-gray-200 text-gray-700 hover:bg-gray-300"
                )
              ]}
            >
              🏛️ Museums (<%= count_by_category(@markers, "museum") %>)
            </button>
          </div>
        </div>

        <%!-- Legend --%>
        <div class="mb-4 p-3 bg-gray-50 rounded">
          <p class="text-xs font-semibold text-gray-700 mb-2">Legend:</p>
          <div class="space-y-1">
            <div class="flex items-center text-xs">
              <div class="w-3 h-3 rounded-full bg-orange-500 mr-2"></div>
              <span>Restaurants</span>
            </div>
            <div class="flex items-center text-xs">
              <div class="w-3 h-3 rounded-full bg-green-500 mr-2"></div>
              <span>Parks</span>
            </div>
            <div class="flex items-center text-xs">
              <div class="w-3 h-3 rounded-full bg-purple-500 mr-2"></div>
              <span>Museums</span>
            </div>
            <div class="flex items-center text-xs">
              <div class="w-3 h-3 rounded-full bg-red-500 mr-2"></div>
              <span>Draggable</span>
            </div>
          </div>
        </div>

        <%!-- Info --%>
        <div class="mt-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
          <h3 class="font-semibold mb-2 text-sm text-blue-900">About:</h3>
          <p class="text-xs text-blue-800">
            Click markers to see details. Drag the red marker to move it around the map.
            Use the filter buttons to show/hide marker categories.
          </p>
          <p class="text-xs text-blue-600 mt-2">
            Showing: <%= length(filtered_markers(assigns)) %> of <%= length(@markers) + 1 %> markers
          </p>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

  defp filtered_markers(assigns) do
    if assigns.filter_category == "all" do
      assigns.markers
    else
      Enum.filter(assigns.markers, fn m -> m.category == assigns.filter_category end)
    end
  end

  defp count_by_category(markers, category) do
    Enum.count(markers, fn m -> m.category == category end)
  end

  # Event Handlers

  @impl true
  def handle_event("set_filter", %{"category" => category}, socket) do
    {:noreply, assign(socket, :filter_category, category)}
  end

  @impl true
  def handle_event("marker:clicked", %{"markerId" => marker_id}, socket) do
    IO.inspect(marker_id, label: "Marker clicked")
    {:noreply, socket}
  end

  @impl true
  def handle_event("marker:drag_start", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("marker:dragging", %{"lngLat" => lng_lat}, socket) do
    {:noreply, assign(socket, :draggable_marker, lng_lat)}
  end

  @impl true
  def handle_event("marker:drag_end", %{"lngLat" => lng_lat}, socket) do
    IO.inspect(lng_lat, label: "Marker dragged to")
    {:noreply, assign(socket, :draggable_marker, lng_lat)}
  end

  @impl true
  def handle_event("map:loaded", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:moved", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:zoom_changed", _params, socket) do
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

  # Data generation

  defp generate_initial_markers do
    [
      # Restaurants (orange)
      %{
        id: "restaurant-1",
        category: "restaurant",
        name: "Italian Bistro",
        position: [-73.99, 40.75],
        color: "#FF8C42",
        popup_html:
          "<strong>🍝 Italian Bistro</strong><br/><small>Fine Italian cuisine<br/>⭐⭐⭐⭐</small>"
      },
      %{
        id: "restaurant-2",
        category: "restaurant",
        name: "Sushi Palace",
        position: [-73.98, 40.76],
        color: "#FF8C42",
        popup_html: "<strong>🍣 Sushi Palace</strong><br/><small>Fresh sushi daily<br/>⭐⭐⭐⭐⭐</small>"
      },
      %{
        id: "restaurant-3",
        category: "restaurant",
        name: "Burger Joint",
        position: [-73.975, 40.755],
        color: "#FF8C42",
        popup_html:
          "<strong>🍔 Burger Joint</strong><br/><small>Best burgers in town<br/>⭐⭐⭐⭐</small>"
      },
      # Parks (green)
      %{
        id: "park-1",
        category: "park",
        name: "Central Park",
        position: [-73.968, 40.785],
        color: "#4CAF50",
        popup_html:
          "<strong>🌳 Central Park</strong><br/><small>843 acres of green space<br/>Open 6AM - 1AM</small>"
      },
      %{
        id: "park-2",
        category: "park",
        name: "Riverside Park",
        position: [-73.992, 40.78],
        color: "#4CAF50",
        popup_html:
          "<strong>🌲 Riverside Park</strong><br/><small>Scenic river views<br/>Open all day</small>"
      },
      # Museums (purple)
      %{
        id: "museum-1",
        category: "museum",
        name: "Art Museum",
        position: [-73.963, 40.779],
        color: "#9C27B0",
        popup_html:
          "<strong>🏛️ Art Museum</strong><br/><small>World-class art collection<br/>$25 admission</small>"
      },
      %{
        id: "museum-2",
        category: "museum",
        name: "Natural History",
        position: [-73.974, 40.781],
        color: "#9C27B0",
        popup_html:
          "<strong>🦖 Natural History Museum</strong><br/><small>Dinosaurs and more!<br/>$23 admission</small>"
      },
      %{
        id: "museum-3",
        category: "museum",
        name: "Science Center",
        position: [-73.995, 40.748],
        color: "#9C27B0",
        popup_html:
          "<strong>🔬 Science Center</strong><br/><small>Interactive exhibits<br/>$20 admission</small>"
      }
    ]
  end
end
