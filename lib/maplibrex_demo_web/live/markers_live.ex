defmodule MaplibrexDemoWeb.MarkersLive do
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}
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
    <div class="relative w-full h-screen overflow-hidden bg-[#050810]">
      <%!-- Map full-screen --%>
      <.map
        id="markers-map"
        center={[-73.985, 40.758]}
        zoom={12}
        pitch={0}
        bearing={0}
        style="https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json"
        class="absolute inset-0 w-full h-full"
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
        popup_text="Drag me around!"
      />

      <%!-- Static Markers (filtered) --%>
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

      <%!-- Back nav pill --%>
      <div class="absolute top-[110px] left-4 z-20 flex flex-col gap-2">
        <a href="/" class="flex items-center gap-2 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-4 py-2 text-sm text-white/70 hover:text-white transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] no-underline">
          {gettext("Back to Demos")}
        </a>
        <div class="flex items-center gap-1 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-3 py-1.5">
          <a href={"/locale?locale=en&return_to=/markers"} class={if @locale == "en", do: "text-[10px] font-semibold text-cyan-300 no-underline", else: "text-[10px] font-medium text-white/40 hover:text-white/70 no-underline"}>EN</a>
          <span class="text-white/20 text-[10px]">|</span>
          <a href={"/locale?locale=es&return_to=/markers"} class={if @locale == "es", do: "text-[10px] font-semibold text-cyan-300 no-underline", else: "text-[10px] font-medium text-white/40 hover:text-white/70 no-underline"}>ES</a>
        </div>
      </div>

      <%!-- Control Panel --%>
      <div class="absolute top-4 right-4 bottom-16 w-72 z-20 overflow-y-auto">
        <div class="bg-[rgba(8,12,28,0.85)] backdrop-blur-xl border border-white/[0.09] rounded-2xl p-5 space-y-5">
          <%!-- Header --%>
          <div>
            <h2 class="text-sm font-semibold text-white tracking-wide">{gettext("Markers & Filters")}</h2>
            <p class="text-[11px] text-white/40 mt-0.5 leading-relaxed">
              {gettext("Category-based marker management with drag-to-update positioning")}
            </p>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Draggable Marker Position --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              {gettext("Draggable Marker")}
            </p>
            <div class="bg-white/[0.04] border border-white/[0.07] rounded-xl p-3 space-y-1.5">
              <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Current Position")}</p>
              <div class="flex gap-3">
                <div>
                  <p class="text-[9px] text-white/40">LNG</p>
                  <p class="font-mono text-xs text-cyan-300">
                    {Float.round(Enum.at(@draggable_marker, 0), 4)}
                  </p>
                </div>
                <div class="w-px bg-white/10"></div>
                <div>
                  <p class="text-[9px] text-white/40">LAT</p>
                  <p class="font-mono text-xs text-cyan-300">
                    {Float.round(Enum.at(@draggable_marker, 1), 4)}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Filter Category --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              {gettext("Filter Category")}
            </p>
            <div class="space-y-1.5">
              <button
                phx-click="set_filter"
                phx-value-category="all"
                class={
                  if @filter_category == "all",
                    do:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                    else:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300"
                }
              >
                <span class="flex items-center justify-between">
                  <span>{gettext("All")}</span>
                  <span class="font-mono text-[11px] opacity-60">{length(@markers)}</span>
                </span>
              </button>
              <button
                phx-click="set_filter"
                phx-value-category="restaurant"
                class={
                  if @filter_category == "restaurant",
                    do:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                    else:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300"
                }
              >
                <span class="flex items-center justify-between">
                  <span>{gettext("Restaurants")}</span>
                  <span class="font-mono text-[11px] opacity-60">
                    {count_by_category(@markers, "restaurant")}
                  </span>
                </span>
              </button>
              <button
                phx-click="set_filter"
                phx-value-category="park"
                class={
                  if @filter_category == "park",
                    do:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                    else:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300"
                }
              >
                <span class="flex items-center justify-between">
                  <span>{gettext("Parks")}</span>
                  <span class="font-mono text-[11px] opacity-60">
                    {count_by_category(@markers, "park")}
                  </span>
                </span>
              </button>
              <button
                phx-click="set_filter"
                phx-value-category="museum"
                class={
                  if @filter_category == "museum",
                    do:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                    else:
                      "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/65 hover:text-white bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-white/[0.12] transition-all duration-300"
                }
              >
                <span class="flex items-center justify-between">
                  <span>{gettext("Museums")}</span>
                  <span class="font-mono text-[11px] opacity-60">
                    {count_by_category(@markers, "museum")}
                  </span>
                </span>
              </button>
            </div>
          </div>

          <div class="h-px bg-white/[0.06]"></div>

          <%!-- Legend --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              {gettext("Legend")}
            </p>
            <div class="space-y-2">
              <div class="flex items-center gap-2.5">
                <div class="w-2.5 h-2.5 rounded-full bg-[#FF6B6B] flex-shrink-0"></div>
                <span class="text-xs text-white/55">{gettext("Draggable")}</span>
              </div>
              <div class="flex items-center gap-2.5">
                <div class="w-2.5 h-2.5 rounded-full bg-[#FF9F43] flex-shrink-0"></div>
                <span class="text-xs text-white/55">{gettext("Restaurants")}</span>
              </div>
              <div class="flex items-center gap-2.5">
                <div class="w-2.5 h-2.5 rounded-full bg-[#48C774] flex-shrink-0"></div>
                <span class="text-xs text-white/55">{gettext("Parks")}</span>
              </div>
              <div class="flex items-center gap-2.5">
                <div class="w-2.5 h-2.5 rounded-full bg-[#8E44AD] flex-shrink-0"></div>
                <span class="text-xs text-white/55">{gettext("Museums")}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- Telemetry --%>
      <div class="absolute bottom-4 left-4 z-20">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-xl px-4 py-3 flex items-center gap-4">
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("City")}</p>
            <p class="font-mono text-xs text-cyan-300/90">NYC</p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Zoom")}</p>
            <p class="font-mono text-xs text-cyan-300/90">12</p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Filter")}</p>
            <p class="font-mono text-xs text-cyan-300/90">{@filter_category}</p>
          </div>
          <div class="w-px h-6 bg-white/10"></div>
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Showing")}</p>
            <p class="font-mono text-xs text-cyan-300/90">
              {length(filtered_markers(assigns))} / {length(@markers) + 1}
            </p>
          </div>
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
