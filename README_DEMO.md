# MaplibreX Demo Application

Esta es una aplicación Phoenix de demostración que muestra cómo integrar y usar MaplibreX en un proyecto real.

## Características Demostradas

1. **Mapa Interactivo** - Renderizado completo con MapLibre GL JS
2. **Control Programático** - Botones para controlar el mapa desde LiveView
3. **Marcadores Interactivos** - Múltiples marcadores con diferentes estilos
4. **Drag & Drop** - Marcador azul draggable que actualiza su estado en tiempo real
5. **Popups** - Información contextual en marcadores
6. **Eventos Bidireccionales** - Comunicación LiveView ↔ MapLibre perfecta
7. **Estado Reactivo** - Actualización automática del UI

## Cómo Ejecutar

```bash
# 1. Instalar dependencias (ya hecho)
mix deps.get

# 2. Compilar assets (ya hecho)
mix assets.build

# 3. Ejecutar servidor
mix phx.server
```

Luego visita:
- Home: http://localhost:4000
- Demo Mapa: http://localhost:4000/map

## Estructura del Proyecto

```
maplibrex_demo/
├── lib/
│   └── maplibrex_demo_web/
│       ├── live/
│       │   └── map_live.ex          # LiveView con mapa
│       └── router.ex                 # Ruta /map configurada
│
├── assets/
│   ├── js/
│   │   └── app.js                    # MapHooks importados
│   └── css/
│       └── app.css                   # MaplibreX CSS importado
│
└── mix.exs                           # MaplibreX como dependencia local
```

## Integración de MaplibreX

### 1. Dependencia en mix.exs
```elixir
defp deps do
  [
    # ...
    {:maplibrex, github: "roger120981/maplibrex"}
  ]
end
```

### 2. Instalar dependencias
```bash
# Instalar dependencias de Elixir
mix deps.get
mix deps.compile

# Instalar dependencias npm de maplibrex
cd deps/maplibrex/assets && npm install && cd ../../..

# Construir assets
mix assets.build
```

### 3. JavaScript Hooks (assets/js/app.js)
```javascript
import {MapHooks} from "../../deps/maplibrex/assets/js/maplibrex"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: MapHooks,
  params: {_csrf_token: csrfToken}
})
```

### 4. CSS (assets/css/app.css)
```css
@import "../../deps/maplibrex/assets/css/maplibrex.css";
```

### 4. LiveView (lib/maplibrex_demo_web/live/map_live.ex)
```elixir
defmodule MaplibrexDemoWeb.MapLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components

  def render(assigns) do
    ~H"""
    <.map
      id="demo-map"
      center={@center}
      zoom={@zoom}
      style="https://demotiles.maplibre.org/style.json"
      class="w-full h-96"
    />
    
    <.marker
      id="marker-1"
      map_id="demo-map"
      lng_lat={[-74.5, 40]}
      color="red"
      draggable
    />
    """
  end
  
  def handle_event("marker:drag_end", %{"lngLat" => pos}, socket) do
    # Actualizar estado
    {:noreply, assign(socket, :marker_position, pos)}
  end
end
```

## Estado del Demo

✅ **Funcionalidades Operativas**
- ✅ Mapa interactivo renderiza correctamente
- ✅ Zoom con mouse wheel (sin re-renders)
- ✅ Pan arrastrando el mapa
- ✅ Marcadores con diferentes colores
- ✅ Marcador draggable (azul) con eventos
- ✅ Popups informativos
- ✅ Eventos del mapa (map:moved, map:clicked, map:loaded, map:zoom_changed)
- ✅ Sin crashes ni pantallas en blanco

⚠️ **Limitaciones Conocidas**
- ⚠️ Los botones de control programático (Fly to NYC, Zoom In, Zoom Out) no funcionan actualmente
  - Esto parece ser una limitación en cómo maplibrex procesa comandos JS desde el servidor
  - Los comandos se envían correctamente pero el hook no los procesa
  - Requiere investigación adicional en el código TypeScript del hook

✅ **Compilación Exitosa**
- Elixir: `Generated maplibrex_demo app`
- TypeScript: Sin errores
- Assets: Correctamente importados desde GitHub

## Próximos Pasos

Experimenta con:
- Agregar más marcadores dinámicamente
- Cambiar el estilo del mapa
- Implementar clustering
- Agregar capas GeoJSON
- Personalizar popups con HTML

## Notas

- MaplibreX se importa como dependencia desde GitHub: `roger120981/maplibrex`
- Las dependencias npm de maplibrex deben instalarse manualmente: `cd deps/maplibrex/assets && npm install`
- Los hooks se cargan automáticamente desde los assets compilados
- El CSS de MapLibre se incluye automáticamente
