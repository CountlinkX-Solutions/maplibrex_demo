# MaplibreX Demo

A Phoenix application exercising every part of
[MaplibreX](https://github.com/CountlinkX-Solutions/maplibrex) — MapLibre GL JS
as Phoenix LiveView components.

Nine demos, each a single LiveView:

| Route | What it shows |
| --- | --- |
| `/map` | Markers, a GeoJSON layer, reactive style switching, client-side map commands |
| `/markers` | Category filtering, HTML popups, drag-to-update positioning |
| `/heatmap` | A heatmap layer with live radius, intensity and opacity |
| `/buildings` | `fill-extrusion` 3D buildings with data-driven colour expressions |
| `/terrain` | 3D terrain from a raster-DEM source, with hillshade |
| `/deckgl` | deck.gl `ArcLayer`, `HexagonLayer` and `ScatterplotLayer` overlays |
| `/particles` | A custom WebGL layer driven by hand-written GLSL shaders |
| `/tiles` | Vector tiles from a self-hosted tile server |
| `/ogc` | OGC API - Features conformance checks against real data |

## Running it

```bash
mix setup
mix phx.server
```

Then open <http://localhost:4003>.

`mix setup` fetches the Elixir dependencies, installs the JavaScript
dependencies (`maplibre-gl` and the `@deck.gl/*` packages, which MaplibreX
declares as peer dependencies), and builds the assets.

> **maplibre-gl is pinned to v5 here.** MaplibreX itself supports `>=5 <7`, but
> this demo includes `/deckgl`, and `@deck.gl/mapbox` still reads the internal
> `map.transform` that maplibre-gl v6 removed. Every other page in this demo
> runs unchanged on v6 — verified in a browser against 6.6.0.

## Developing against a local MaplibreX checkout

Set `MAPLIBREX_PATH` and both the Elixir dependency and the npm package resolve
to your working copy instead of GitHub:

```bash
git clone https://github.com/CountlinkX-Solutions/maplibrex.git ../maplibrex

MAPLIBREX_PATH=../maplibrex mix deps.get
MAPLIBREX_PATH=../maplibrex mix assets.setup
MAPLIBREX_PATH=../maplibrex mix phx.server
```

Rebuild the library's bundle after changing its TypeScript:

```bash
cd ../maplibrex && mix assets.build
```

## The `/tiles` and `/ogc` demos need a tile server

Every other demo runs against public basemaps and needs nothing external.
These two read from a separate vector tile / OGC Features server, configured by
`:tile_server_url` (default `http://localhost:4000`):

```bash
TILE_SERVER_URL=https://tiles.example.com mix phx.server
```

When that server is not reachable, both pages say so in the control panel;
`/tiles` also falls back to a public basemap so the page still works.

## How MaplibreX is wired in

**`mix.exs`** — the dependency, with the local-checkout override:

```elixir
defp maplibrex_dep do
  case System.get_env("MAPLIBREX_PATH") do
    nil -> {:maplibrex, github: "CountlinkX-Solutions/maplibrex"}
    path -> {:maplibrex, path: path}
  end
end
```

**`assets/js/app.js`** — register the hooks:

```javascript
import {MapHooks} from "maplibrex"

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: MapHooks
})
```

**`assets/css/app.css`** — MapLibre's stylesheet first, then MaplibreX's:

```css
@import "maplibre-gl/dist/maplibre-gl.css";
@import "maplibrex/css";
```

**A LiveView** — components and `handle_event/3`, no custom JavaScript:

```elixir
defmodule MaplibrexDemoWeb.MapLive do
  use MaplibrexDemoWeb, :live_view
  import MaplibreX.Components
  alias MaplibreX.Components.Map, as: MapCmd

  def render(assigns) do
    ~H"""
    <.map id="demo-map" center={@center} zoom={@zoom} style={@current_style}
          class="absolute inset-0 h-full w-full" />

    <.marker :for={m <- @markers} id={m.id} map_id="demo-map"
             lng_lat={m.lng_lat} color={m.color} draggable={m.draggable} />

    <button phx-click={MapCmd.fly_to("demo-map", [-73.98, 40.75], 12)}>NYC</button>
    """
  end

  def handle_event("marker:drag_end", %{"markerId" => id, "lngLat" => lng_lat}, socket) do
    # ...
  end
end
```

## Layout of the demo itself

- `lib/maplibrex_demo_web/components/demo_components.ex` — the shared chrome
  every demo page is built from: the shell, control panel, sliders, telemetry
  bar, legend. Each LiveView contains only its map and its own controls.
- `lib/maplibrex_demo_web/live/*.ex` — one LiveView per demo.
- `lib/maplibrex_demo_web/controllers/page_controller.ex` — the demo catalogue
  rendered on the landing page.

The UI is available in English and Spanish through Gettext; the switcher is in
the top-left of every page.

## Asset build notes

`config/config.exs` configures esbuild with two flags worth knowing about:

- `--splitting` (with `--format=esm`) keeps deck.gl out of the main bundle.
  MaplibreX imports it dynamically, so only `/deckgl` downloads it. This is why
  `root.html.heex` loads `app.js` as `type="module"`.
- `--preserve-symlinks` is needed because `maplibrex` is installed as a `file:`
  dependency, which npm links rather than copies. Without it esbuild resolves
  the bundle's peer imports relative to the library's real path instead of this
  application's `node_modules`.

## License

MIT.
