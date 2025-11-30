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
    {:maplibrex, path: "../maplibrex"}
  ]
end
```

### 2. JavaScript Hooks (assets/js/app.js)
```javascript
import { MapHooks } from "../../maplibrex/priv/static/assets/js/maplibrex"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: MapHooks,
  params: {_csrf_token: csrfToken}
})
```

### 3. CSS (assets/css/app.css)
```css
@import "../../maplibrex/priv/static/assets/js/maplibrex.css";
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

## Verificación

✅ **Compilación Exitosa**
- Elixir: `Generated maplibrex_demo app`
- TypeScript: Sin errores
- Assets: Correctamente importados

✅ **Funcionalidades**
- Map component renderiza
- Marker components funcionan
- Eventos bidireccionales
- Control programático
- Drag & drop

## Próximos Pasos

Experimenta con:
- Agregar más marcadores dinámicamente
- Cambiar el estilo del mapa
- Implementar clustering
- Agregar capas GeoJSON
- Personalizar popups con HTML

## Notas

- MaplibreX se importa como dependencia local desde `../maplibrex`
- Los hooks se cargan automáticamente desde los assets compilados
- El CSS de MapLibre se incluye automáticamente
