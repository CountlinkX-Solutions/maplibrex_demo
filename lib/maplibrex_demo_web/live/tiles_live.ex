defmodule MaplibrexDemoWeb.TilesLive do
  use MaplibrexDemoWeb, :live_view
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
        %{id: "default", name: "Default", description: "Auto-generado con todas las fuentes"},
        %{id: "dark", name: "Dark", description: "Tema oscuro con efectos de brillo"},
        %{id: "light", name: "Light", description: "Tema claro minimalista"},
        %{id: "advanced", name: "Advanced", description: "Con expresiones y estilos avanzados"}
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
    <div class="p-8">
      <div class="mb-6">
        <h1 class="text-3xl font-bold mb-2">🗺️ Vector Tiles Server Demo</h1>
        <p class="text-gray-600">
          Conectado a servidor local de tiles vectoriales en <code class="bg-gray-100 px-2 py-1 rounded"><%= @server_url %></code>
        </p>
      </div>

      <%!-- Selector de Estilos --%>
      <div class="mb-4">
        <h3 class="font-semibold text-gray-700 mb-3">Estilos Disponibles:</h3>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
          <%= for style <- @available_styles do %>
            <button
              phx-click="change_style"
              phx-value-style={style.id}
              class={[
                "p-4 rounded-lg border-2 transition-all text-left",
                if(@current_style == style.id,
                  do: "border-blue-500 bg-blue-50 shadow-lg",
                  else: "border-gray-200 hover:border-blue-300 hover:shadow"
                )
              ]}
            >
              <div class="font-bold text-lg mb-1"><%= style.name %></div>
              <div class="text-sm text-gray-600"><%= style.description %></div>
              <%= if @current_style == style.id do %>
                <div class="mt-2 text-blue-600 text-sm font-semibold">✓ Activo</div>
              <% end %>
            </button>
          <% end %>
        </div>
      </div>

      <%!-- Mapa con Vector Tiles --%>
      <div class="mb-4">
        <.map
          id="tiles-map"
          center={[-74.5, 40]}
          zoom={2}
          style={@current_style_url}
          class="w-full h-[600px] rounded-lg shadow-lg border-2 border-gray-300"
        />

        <.navigation_control
          id="nav-control"
          map_id="tiles-map"
          position="top-right"
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
      </div>

      <%!-- Panel de Información --%>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <%!-- Estado del Mapa --%>
        <div class="p-4 bg-gray-50 rounded-lg border border-gray-200">
          <h3 class="font-bold mb-3 text-lg">📍 Estado del Mapa</h3>
          <div class="space-y-2 text-sm">
            <div>
              <strong>Centro:</strong>
              <span class="font-mono">
                [<%= Float.round(Enum.at(@current_center, 0) * 1.0, 4) %>,
                <%= Float.round(Enum.at(@current_center, 1) * 1.0, 4) %>]
              </span>
            </div>
            <div>
              <strong>Zoom:</strong>
              <span class="font-mono"><%= Float.round(@current_zoom * 1.0, 2) %></span>
            </div>
          </div>
        </div>

        <%!-- Información del Servidor --%>
        <div class="p-4 bg-blue-50 rounded-lg border border-blue-200">
          <h3 class="font-bold mb-3 text-lg">🖥️ Servidor de Tiles</h3>
          <div class="space-y-2 text-sm">
            <div>
              <strong>URL Base:</strong>
              <code class="bg-white px-2 py-1 rounded"><%= @server_url %></code>
            </div>
            <div>
              <strong>Estilo Actual:</strong>
              <span class="font-semibold text-blue-600"><%= @current_style %></span>
            </div>
            <div>
              <strong>URL del Estilo:</strong>
              <code class="bg-white px-2 py-1 rounded text-xs break-all"><%= @current_style_url %></code>
            </div>
          </div>
        </div>
      </div>

      <%!-- Información de Capas --%>
      <div class="mt-4 p-4 bg-green-50 rounded-lg border border-green-200">
        <h3 class="font-bold mb-2 text-lg">🗂️ Capas Vectoriales Disponibles</h3>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-2 text-sm">
          <div class="p-2 bg-white rounded border border-green-300">
            <strong>cities</strong>
            <div class="text-xs text-gray-600">Ciudades (PostgreSQL)</div>
          </div>
          <div class="p-2 bg-white rounded border border-green-300">
            <strong>countries</strong>
            <div class="text-xs text-gray-600">Países (PostgreSQL)</div>
          </div>
          <div class="p-2 bg-white rounded border border-green-300">
            <strong>demo</strong>
            <div class="text-xs text-gray-600">Demo (MBTiles)</div>
          </div>
          <div class="p-2 bg-white rounded border border-green-300">
            <strong>world</strong>
            <div class="text-xs text-gray-600">Mundo (MBTiles)</div>
          </div>
        </div>
      </div>

      <%!-- Enlaces útiles --%>
      <div class="mt-4 p-4 bg-purple-50 rounded-lg border border-purple-200">
        <h3 class="font-bold mb-2">🔗 Enlaces del Servidor</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-2 text-sm">
          <a
            href={"#{@server_url}/styles/#{@current_style}.json"}
            target="_blank"
            class="text-blue-600 hover:underline"
          >
            📄 Ver JSON del estilo actual
          </a>
          <a href={"#{@server_url}/cities.json"} target="_blank" class="text-blue-600 hover:underline">
            📊 TileJSON: cities
          </a>
          <a
            href={"#{@server_url}/countries.json"}
            target="_blank"
            class="text-blue-600 hover:underline"
          >
            📊 TileJSON: countries
          </a>
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
      |> assign(:current_style_url, style_url)

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
