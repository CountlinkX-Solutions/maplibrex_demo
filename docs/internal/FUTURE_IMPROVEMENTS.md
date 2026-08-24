# Mejoras Futuras para MaplibreX Demo

Este documento describe las posibles mejoras y cambios que se pueden hacer al proyecto en el futuro.

## 🔧 Mejoras Prioritarias para maplibrex

### 1. Fix en JS.dispatch() para Phoenix LiveView

**Problema actual:**
`JS.dispatch()` no funciona correctamente con eventos personalizados cuando se usa con `phx-click`. En lugar de disparar eventos DOM personalizados, envía eventos al servidor vía Phoenix.

**Solución propuesta:**
Modificar los componentes helper de maplibrex para que devuelvan comandos JavaScript que disparen eventos DOM directamente, sin usar `phx-click`:

```elixir
# En MaplibreX.Components.Map

def fly_to(map_id, center, zoom, opts \\ []) do
  duration = Keyword.get(opts, :duration, 1000)
  
  # En lugar de JS.dispatch, retornar código JS directo
  %Phoenix.LiveView.JS{}
  |> JS.add_class("cursor-wait", to: "body")
  |> JS.dispatch("maplibrex:fly_to", 
       to: "##{map_id}",
       detail: %{center: center, zoom: zoom, duration: duration})
  |> JS.remove_class("cursor-wait", to: "body", transition: {"", "", ""}, time: 100)
end
```

O mejor aún, crear un helper específico:

```elixir
def map_command(map_id, command, params \\ %{}) do
  """
  this.dispatchEvent(
    new CustomEvent('maplibrex:#{command}', {
      detail: #{Jason.encode!(params)}
    })
  )
  """
end
```

### 2. Debouncing para Eventos Frecuentes

**Problema:**
Los eventos `map:moved` y `map:zoom_changed` se disparan muy frecuentemente, enviando muchos mensajes al servidor.

**Solución:**
Agregar debouncing en el event dispatcher:

```typescript
// En event-dispatcher.ts
private debounce(func: Function, wait: number) {
  let timeout: NodeJS.Timeout;
  return (...args: any[]) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(this, args), wait);
  };
}

setupDefaultMapEvents(): void {
  // Usar debouncing para eventos frecuentes
  const debouncedMoved = this.debounce(() => {
    const center = this.map.getCenter();
    const zoom = this.map.getZoom();
    // ... enviar a LiveView
  }, 100);
  
  this.onMapEvent('moveend', debouncedMoved);
}
```

### 3. Mejor Integración con Phoenix JS Commands

**Problema:**
Los comandos helper no se integran bien con el sistema de comandos JS de Phoenix.

**Solución propuesta:**
Crear un módulo JavaScript exportable que se pueda usar desde `phx-click`:

```javascript
// En maplibrex.ts
export const Commands = {
  flyTo(el, center, zoom, duration = 1000) {
    el.dispatchEvent(new CustomEvent('maplibrex:fly_to', {
      detail: { center, zoom, duration }
    }));
  },
  
  zoomIn(el) {
    el.dispatchEvent(new CustomEvent('maplibrex:zoom_in'));
  },
  
  zoomOut(el) {
    el.dispatchEvent(new CustomEvent('maplibrex:zoom_out'));
  }
};

// Exportar al window para uso global
window.MaplibreX = { Commands };
```

Y en el LiveView:

```elixir
<button phx-click={JS.dispatch("phx:map-fly-to")}>
  Fly to NYC
</button>
```

Con un hook global que escuche:

```javascript
window.addEventListener('phx:map-fly-to', (e) => {
  MaplibreX.Commands.flyTo(
    document.getElementById('demo-map'),
    [-73.98, 40.75],
    12
  );
});
```

## 🎨 Mejoras de UI/UX

### 1. Estado Dinámico del Mapa

**Mejora:**
Actualizar el panel de estado con las coordenadas y zoom actuales sin causar re-renders del mapa.

**Implementación:**
Usar `push_event` selectivo solo para actualizar el estado, no el mapa:

```elixir
def handle_event("map:moved", params, socket) do
  # Actualizar solo el estado de visualización, no el mapa
  socket =
    socket
    |> assign(:display_center, params["center"])
    |> assign(:display_zoom, params["zoom"])
  
  {:noreply, socket}
end
```

Y usar `phx-update="ignore"` solo en el mapa, no en el estado:

```heex
<.map id="demo-map" phx-update="ignore" ... />

<div class="mt-4 p-4 bg-gray-100 rounded">
  <p><strong>Centro actual:</strong> <%= inspect(@display_center) %></p>
  <p><strong>Zoom actual:</strong> <%= @display_zoom %></p>
</div>
```

### 2. Feedback Visual de Comandos

**Mejora:**
Agregar feedback visual cuando se ejecutan comandos (loading, cursor, etc.)

**Implementación:**

```elixir
<button
  onclick="
    this.classList.add('opacity-50', 'cursor-wait');
    document.getElementById('demo-map').dispatchEvent(
      new CustomEvent('maplibrex:fly_to', {
        detail: {center: [-73.98, 40.75], zoom: 12, duration: 1000}
      })
    );
    setTimeout(() => this.classList.remove('opacity-50', 'cursor-wait'), 1000);
  "
  class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 transition-all"
>
  Fly to NYC
</button>
```

### 3. Controles de Navegación Nativos

**Mejora:**
Usar los componentes de control nativos de maplibrex en lugar de botones custom.

**Implementación:**

```heex
<.map id="demo-map" ... />

<.navigation_control 
  map_id="demo-map"
  position="top-right"
  show_compass={true}
  show_zoom={true}
/>

<.fullscreen_control 
  map_id="demo-map"
  position="top-right"
/>
```

## 🧪 Mejoras de Testing

### 1. Tests E2E para Comandos del Mapa

**Implementación:**

```elixir
# test/maplibrex_demo_web/live/map_live_test.exs

test "fly to NYC button works", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/map")
  
  # Simular click en el botón
  view
  |> element("button", "Fly to NYC")
  |> render_click()
  
  # Verificar que el mapa actualizó (via JavaScript)
  # Esto requeriría un test browser real con Wallaby o similar
end
```

### 2. Tests de Integración JavaScript

**Implementación con Wallaby:**

```elixir
feature "map commands work correctly", %{session: session} do
  session
  |> visit("/map")
  |> assert_has(css("#demo-map"))
  |> click(button("Fly to NYC"))
  |> assert_has(css("#demo-map[data-center*='-73.98']"))
end
```

## 📦 Mejoras de Rendimiento

### 1. Lazy Loading del Mapa

**Mejora:**
Cargar el mapa solo cuando sea visible (Intersection Observer)

**Implementación:**

```javascript
// En map-hook.ts
mounted(this: any) {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.initializeMap();
        observer.disconnect();
      }
    });
  });
  
  observer.observe(this.el);
}
```

### 2. Virtualización de Marcadores

**Mejora:**
Para muchos marcadores, solo renderizar los visibles en el viewport.

**Implementación:**
Usar clustering o virtualización basada en bounds del mapa.

## 🔐 Mejoras de Seguridad

### 1. Validación de Coordenadas

**Mejora:**
Validar coordenadas antes de enviarlas al mapa.

**Implementación:**

```elixir
defp validate_coordinates([lng, lat]) when is_number(lng) and is_number(lat) do
  cond do
    lng < -180 or lng > 180 -> {:error, "Invalid longitude"}
    lat < -90 or lat > 90 -> {:error, "Invalid latitude"}
    true -> {:ok, [lng, lat]}
  end
end
```

### 2. Rate Limiting de Eventos

**Mejora:**
Limitar la frecuencia de eventos del mapa para evitar spam.

**Implementación:**

```typescript
// Rate limiter simple
class RateLimiter {
  private lastCall = 0;
  private minInterval: number;

  constructor(minInterval: number) {
    this.minInterval = minInterval;
  }

  canCall(): boolean {
    const now = Date.now();
    if (now - this.lastCall >= this.minInterval) {
      this.lastCall = now;
      return true;
    }
    return false;
  }
}

// Usar en el dispatcher
const moveLimiter = new RateLimiter(100); // max 10 eventos/segundo

this.onMapEvent('move', () => {
  if (moveLimiter.canCall()) {
    this.pushToLiveView('map:moved', payload);
  }
});
```

## 📚 Mejoras de Documentación

### 1. Guía de Integración Completa

**Crear:**
- Guía paso a paso de integración
- Ejemplos de casos de uso comunes
- Troubleshooting guide

### 2. Ejemplos Interactivos

**Crear:**
- Storybook/LiveBook con ejemplos
- Demos de diferentes configuraciones
- Playground interactivo

## 🏗️ Arquitectura

### 1. Separar Lógica de Negocio

**Mejora:**
Mover lógica del LiveView a módulos de contexto.

**Implementación:**

```elixir
defmodule MaplibrexDemo.Maps do
  @moduledoc """
  Context for map-related operations
  """

  def update_marker_position(markers, marker_id, new_position) do
    Enum.map(markers, fn marker ->
      if marker.id == marker_id do
        %{marker | lng_lat: new_position}
      else
        marker
      end
    end)
  end
end
```

### 2. Componentes Reutilizables

**Mejora:**
Crear componentes de función para partes comunes.

**Implementación:**

```elixir
defmodule MaplibrexDemoWeb.MapComponents do
  use Phoenix.Component
  
  def map_controls(assigns) do
    ~H"""
    <div class="flex space-x-2">
      <.map_button command="fly_to" params={@fly_to_params}>
        Fly to <%= @destination %>
      </.map_button>
      
      <.map_button command="zoom_in">
        Zoom In
      </.map_button>
      
      <.map_button command="zoom_out">
        Zoom Out
      </.map_button>
    </div>
    """
  end
  
  def map_button(assigns) do
    ~H"""
    <button
      onclick={"document.getElementById('#{@map_id}').dispatchEvent(
        new CustomEvent('maplibrex:#{@command}', {detail: #{Jason.encode!(@params || %{})}})
      )"}
      class={@class}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
```

## 🎯 Roadmap Sugerido

### Fase 1 (Corto Plazo - 1-2 semanas)
- [ ] Fix de JS.dispatch() en maplibrex
- [ ] Debouncing de eventos frecuentes
- [ ] Documentación básica mejorada

### Fase 2 (Mediano Plazo - 1 mes)
- [ ] Estado dinámico del mapa
- [ ] Feedback visual de comandos
- [ ] Tests E2E básicos

### Fase 3 (Largo Plazo - 3 meses)
- [ ] Lazy loading del mapa
- [ ] Virtualización de marcadores
- [ ] Guía completa de integración
- [ ] Playground interactivo

## 💡 Ideas Adicionales

1. **Multi-mapa:** Soporte para múltiples mapas en la misma página
2. **Temas:** Dark mode / Light mode para el mapa
3. **Exportar:** Exportar el mapa como imagen o PDF
4. **Compartir:** Generar URLs con estado del mapa
5. **Historial:** Navegación de historial de posiciones
6. **Mediciones:** Herramientas para medir distancias
7. **Dibujo:** Herramientas para dibujar en el mapa
8. **Geocoding:** Búsqueda de direcciones integrada

## 🤝 Contribuciones

Este documento está abierto a contribuciones. Si tienes ideas adicionales o mejoras, siéntelas libre de agregarlas.

---

**Última actualización:** 2025-01-04
**Autor:** Demo MaplibreX
**Versión:** 1.0.0
