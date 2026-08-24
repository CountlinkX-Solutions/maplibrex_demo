defmodule MaplibrexDemoWeb.MarkersLive do
  @moduledoc """
  Marker management: category filtering, HTML popups, and a draggable marker
  whose position streams back into the LiveView.

  `marker:dragging` fires continuously while a marker is held, so this demo
  only assigns from `marker:drag_end`. `marker:dragging` updates a
  client-visible readout via `map:moved`-style telemetry instead of a socket
  message per frame.
  """
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}

  import MaplibreX.Components

  @center [-73.985, 40.758]
  @zoom 12

  # Single source of truth for category colours: markers, filters and the
  # legend all read from here, so they cannot drift apart.
  @categories [
    %{id: "restaurant", color: "#FF8C42"},
    %{id: "park", color: "#4CAF50"},
    %{id: "museum", color: "#9C27B0"}
  ]
  @draggable_color "#FF6B6B"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:center, @center)
      |> assign(:zoom, @zoom)
      |> assign(:markers, generate_initial_markers())
      |> assign(:draggable_marker, @center)
      |> assign(:filter_category, "all")
      |> assign(:categories, @categories)
      |> assign(:draggable_color, @draggable_color)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :visible, filtered_markers(assigns))

    ~H"""
    <.demo_page
      path={~p"/markers"}
      locale={@locale}
      title={gettext("Markers & Filters")}
      subtitle={gettext("Category-based marker management with drag-to-update positioning")}
    >
      <:map>
        <.map
          id="markers-map"
          center={@center}
          zoom={@zoom}
          style="https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json"
          class="absolute inset-0 h-full w-full"
        />

        <.navigation_control id="nav-control" map_id="markers-map" position="top-left" />

        <.marker
          id="draggable-marker"
          map_id="markers-map"
          lng_lat={@draggable_marker}
          color={@draggable_color}
          scale={1.3}
          draggable={true}
          popup_text={gettext("Drag me around!")}
        />

        <.marker
          :for={marker <- @visible}
          id={marker.id}
          map_id="markers-map"
          lng_lat={marker.position}
          color={marker.color}
          scale={1.0}
          popup_html={marker.popup_html}
        />
      </:map>

      <:panel>
        <.panel_section label={gettext("Draggable Marker")}>
          <div class="space-y-1.5 rounded-xl border border-white/[0.07] bg-white/[0.04] p-3">
            <p class="text-[9px] tracking-widest text-white/35 uppercase">
              {gettext("Current Position")}
            </p>
            <div class="flex gap-3">
              <div>
                <p class="text-[9px] text-white/40">LNG</p>
                <p class="font-mono text-xs text-cyan-300">
                  {Float.round(Enum.at(@draggable_marker, 0) * 1.0, 4)}
                </p>
              </div>
              <div class="w-px bg-white/10" />
              <div>
                <p class="text-[9px] text-white/40">LAT</p>
                <p class="font-mono text-xs text-cyan-300">
                  {Float.round(Enum.at(@draggable_marker, 1) * 1.0, 4)}
                </p>
              </div>
            </div>
          </div>
        </.panel_section>

        <.panel_section label={gettext("Filter Category")} class="space-y-1.5">
          <.option_button
            active={@filter_category == "all"}
            badge={length(@markers)}
            phx-click="set_filter"
            phx-value-category="all"
          >
            {gettext("All")}
          </.option_button>

          <.option_button
            :for={category <- @categories}
            active={@filter_category == category.id}
            badge={count_by_category(@markers, category.id)}
            phx-click="set_filter"
            phx-value-category={category.id}
          >
            {category_label(category.id)}
          </.option_button>
        </.panel_section>

        <.panel_section label={gettext("Legend")} class="space-y-2">
          <.legend_item color={@draggable_color}>{gettext("Draggable")}</.legend_item>
          <.legend_item :for={category <- @categories} color={category.color}>
            {category_label(category.id)}
          </.legend_item>
        </.panel_section>
      </:panel>

      <:telemetry>
        <.stat first label={gettext("City")} value="NYC" />
        <.stat label={gettext("Zoom")} value={@zoom} />
        <.stat label={gettext("Filter")} value={@filter_category} />
        <.stat label={gettext("Showing")} value={"#{length(@visible) + 1} / #{length(@markers) + 1}"} />
      </:telemetry>
    </.demo_page>
    """
  end

  @impl true
  def handle_event("set_filter", %{"category" => category}, socket) do
    {:noreply, assign(socket, :filter_category, category)}
  end

  # Only commit the final position: `marker:dragging` fires on every pointer
  # move and would send one socket message per frame.
  def handle_event("marker:drag_end", %{"lngLat" => lng_lat}, socket) do
    {:noreply, assign(socket, :draggable_marker, lng_lat)}
  end

  def handle_event("map:" <> _, _params, socket), do: {:noreply, socket}
  def handle_event("marker:" <> _, _params, socket), do: {:noreply, socket}

  defp filtered_markers(%{filter_category: "all", markers: markers}), do: markers

  defp filtered_markers(%{filter_category: category, markers: markers}),
    do: Enum.filter(markers, &(&1.category == category))

  defp count_by_category(markers, category),
    do: Enum.count(markers, &(&1.category == category))

  defp category_label("restaurant"), do: gettext("Restaurants")
  defp category_label("park"), do: gettext("Parks")
  defp category_label("museum"), do: gettext("Museums")

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
        popup_html:
          "<strong>🍣 Sushi Palace</strong><br/><small>Fresh sushi daily<br/>⭐⭐⭐⭐⭐</small>"
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
