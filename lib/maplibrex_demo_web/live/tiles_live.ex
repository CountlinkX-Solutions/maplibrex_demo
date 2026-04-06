defmodule MaplibrexDemoWeb.TilesLive do
  use MaplibrexDemoWeb, :live_view
  on_mount {MaplibrexDemoWeb.LocaleHook, :set_locale}
  import MaplibreX.Components

  @server_url "http://localhost:4000"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:server_url, @server_url)
      |> assign(:current_style, "default")
      |> assign(:current_style_url, "#{@server_url}/styles/default.json")
      |> assign(:available_styles, [
        %{id: "default", name: "Default", description: gettext("Auto-generated with all sources")},
        %{id: "dark", name: "Dark", description: gettext("Dark theme with glow effects")},
        %{id: "light", name: "Light", description: gettext("Minimal light theme")},
        %{id: "advanced", name: "Advanced", description: gettext("With expressions and advanced styles")}
      ])
      |> assign(:current_center, [-74.5, 40])
      |> assign(:current_zoom, 2)
      |> assign(:server_status, :unknown)
      |> assign(:sources_info, [])

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-full h-screen overflow-hidden bg-[#050810]">
      <%!-- Map fills full screen --%>
      <.map
        id="tiles-map"
        center={[-74.5, 40]}
        zoom={2}
        style={@current_style_url}
        class="absolute inset-0 w-full h-full"
      />

      <%!-- Map controls --%>
      <.navigation_control
        id="nav-control"
        map_id="tiles-map"
        position="top-left"
        show_compass={true}
        show_zoom={true}
        visualize_pitch={false}
      />

      <.scale_control
        id="scale-control"
        map_id="tiles-map"
        position="bottom-left"
        max_width={150}
        unit="metric"
      />

      <.fullscreen_control
        id="fullscreen-control"
        map_id="tiles-map"
        position="top-left"
      />

      <%!-- Back navigation pill --%>
      <div class="absolute top-[110px] left-4 z-20 flex flex-col gap-2">
        <a href="/" class="flex items-center gap-2 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-4 py-2 text-sm text-white/70 hover:text-white transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)] no-underline">
          {gettext("Back to Demos")}
        </a>
        <div class="flex items-center gap-1 bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-full px-3 py-1.5">
          <a href={"/locale?locale=en&return_to=/tiles"} class={if @locale == "en", do: "text-[10px] font-semibold text-cyan-300 no-underline", else: "text-[10px] font-medium text-white/40 hover:text-white/70 no-underline"}>EN</a>
          <span class="text-white/20 text-[10px]">|</span>
          <a href={"/locale?locale=es&return_to=/tiles"} class={if @locale == "es", do: "text-[10px] font-semibold text-cyan-300 no-underline", else: "text-[10px] font-medium text-white/40 hover:text-white/70 no-underline"}>ES</a>
        </div>
      </div>

      <%!-- Control Panel --%>
      <div class="absolute top-4 right-4 bottom-16 w-72 z-20 overflow-y-auto">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-2xl p-5 space-y-5">
          <%!-- Title --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-1">
              MaplibreX
            </p>
            <h2 class="text-base font-semibold text-white">{gettext("Vector Tiles Server")}</h2>
            <p class="text-xs text-white/50 mt-1">
              {gettext("Live tile rendering from localhost:4000")}
            </p>
          </div>

          <div class="border-t border-white/[0.06]" />

          <%!-- Style selector --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              {gettext("Style")}
            </p>
            <div class="space-y-1">
              <%= for style <- @available_styles do %>
                <button
                  phx-click="change_style"
                  phx-value-style={style.id}
                  class={
                    if @current_style == style.id,
                      do: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-cyan-300 bg-cyan-500/10 border border-cyan-400/25",
                      else: "w-full text-left px-3 py-2.5 rounded-lg text-sm text-white/70 hover:text-white hover:bg-white/[0.07] border border-transparent hover:border-white/[0.08] transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"
                  }
                >
                  <span class="font-medium">{style.name}</span>
                  <span class="block text-xs text-white/40 mt-0.5">{style.description}</span>
                </button>
              <% end %>
            </div>
          </div>

          <div class="border-t border-white/[0.06]" />

          <%!-- Vector Layers --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              {gettext("Vector Layers")}
            </p>
            <div class="flex flex-wrap gap-1.5">
              <span class="inline-flex px-2 py-1 rounded text-[10px] bg-white/[0.05] border border-white/[0.07] text-white/60">
                cities
              </span>
              <span class="inline-flex px-2 py-1 rounded text-[10px] bg-white/[0.05] border border-white/[0.07] text-white/60">
                countries
              </span>
              <span class="inline-flex px-2 py-1 rounded text-[10px] bg-white/[0.05] border border-white/[0.07] text-white/60">
                demo
              </span>
              <span class="inline-flex px-2 py-1 rounded text-[10px] bg-white/[0.05] border border-white/[0.07] text-white/60">
                world
              </span>
            </div>
          </div>

          <div class="border-t border-white/[0.06]" />

          <%!-- Server Links --%>
          <div>
            <p class="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35 mb-2">
              {gettext("Server Links")}
            </p>
            <div class="space-y-1">
              <a
                href={"#{@server_url}/styles/#{@current_style}.json"}
                target="_blank"
                class="flex items-center justify-between w-full px-3 py-2 rounded-lg text-xs text-white/60 hover:text-white bg-white/[0.03] hover:bg-white/[0.07] border border-white/[0.06] transition-all duration-300"
              >
                <span>{gettext("Style JSON")}</span>
                <span class="text-white/30">→</span>
              </a>
              <a
                href={"#{@server_url}/cities.json"}
                target="_blank"
                class="flex items-center justify-between w-full px-3 py-2 rounded-lg text-xs text-white/60 hover:text-white bg-white/[0.03] hover:bg-white/[0.07] border border-white/[0.06] transition-all duration-300"
              >
                <span>TileJSON: cities</span>
                <span class="text-white/30">→</span>
              </a>
              <a
                href={"#{@server_url}/countries.json"}
                target="_blank"
                class="flex items-center justify-between w-full px-3 py-2 rounded-lg text-xs text-white/60 hover:text-white bg-white/[0.03] hover:bg-white/[0.07] border border-white/[0.06] transition-all duration-300"
              >
                <span>TileJSON: countries</span>
                <span class="text-white/30">→</span>
              </a>
            </div>
          </div>
        </div>
      </div>

      <%!-- Telemetry panel --%>
      <div class="absolute bottom-4 left-4 z-20">
        <div class="bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09] rounded-xl px-4 py-3 flex items-center gap-4">
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Center")}</p>
            <p class="font-mono text-xs text-cyan-300">
              {Float.round(Enum.at(@current_center, 0) * 1.0, 3)},
              {Float.round(Enum.at(@current_center, 1) * 1.0, 3)}
            </p>
          </div>
          <div class="w-px h-6 bg-white/10" />
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Zoom")}</p>
            <p class="font-mono text-xs text-cyan-300">
              {Float.round(@current_zoom * 1.0, 1)}
            </p>
          </div>
          <div class="w-px h-6 bg-white/10" />
          <div>
            <p class="text-[9px] uppercase tracking-widest text-white/35">{gettext("Style")}</p>
            <p class="font-mono text-xs text-cyan-300 capitalize">{@current_style}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("change_style", %{"style" => style_id}, socket) do
    style_url = "#{@server_url}/styles/#{style_id}.json"

    socket =
      socket
      |> assign(:current_style, style_id)
      |> push_event("map:set_style", %{map_id: "tiles-map", style: style_url})

    {:noreply, socket}
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
  def handle_event("map:clicked", %{"lngLat" => lng_lat}, socket) do
    IO.inspect(lng_lat, label: "Map clicked at")
    {:noreply, socket}
  end

  @impl true
  def handle_event("map:error", %{"error" => error}, socket) do
    IO.inspect(error, label: "Map error")
    {:noreply, socket}
  end
end
