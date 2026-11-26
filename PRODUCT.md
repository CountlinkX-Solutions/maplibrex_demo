# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Elixir developers evaluating MaplibreX. They arrive from Hex or GitHub, clone this repository and run it locally to decide, in a few minutes, whether the library fits their project: they want to see what each component does and copy the code that produces it. (Confirmed by the owner, 2026-11-25.)

## Product Purpose

MaplibreX Demo is the runnable showcase of MaplibreX, a library of MapLibre GL JS components for Phoenix LiveView. It exists so that an evaluating developer can see every feature family of the library working, with the code behind it, and can tell what is stable, what is limited and what is planned. Success: the demo stays in step with the library's features and roadmap, and a visitor can find any component and its example without reading the library source.

The demo also serves as the library's browser check during development: each slice of library work is run against it with `MAPLIBREX_PATH`.

## Positioning

The map is declared in HEEx and driven from the server: assigns change the map, map events arrive as LiveView events, and no JavaScript is written by the application. The demo proves this by showing the template and the `handle_event` next to the running map.

## Operating Context

- Runs locally only: `mix setup` and `mix phx.server` (dev port 4003). There is no public deployment and none is planned.
- Resolves the library from GitHub by default, or from a local checkout with `MAPLIBREX_PATH=../maplibrex`.
- Basemaps and data come from public services (OpenFreeMap, MapLibre demo tiles, Mapterhorn DEM, NASA GIBS imagery, sample images from the MapLibre GL JS documentation). No tile server of its own is needed; the old `/tiles` and `/ogc` pages are gone and their URLs redirect to the catalogue.
- Interface copy is bilingual, English and Spanish, through Gettext.

## Capabilities and Constraints

- Phoenix 1.8, LiveView 1.2, Tailwind CSS 4. Repository rules for building pages are in `AGENTS.md`.
- MaplibreX 0.1.1 ships 32 components in these families: map; markers and popups; layers (GeoJSON plus nine typed layers); sources (vector, raster, raster DEM, image, video); controls (navigation, scale, attribution, fullscreen, geolocate, terrain control, and custom-control building blocks); 3D (terrain, sky); advanced (deck.gl layers, custom WebGL layers). As of 2026-11-26 the demo uses 29 of them, 27 with an interactive example of their own; `deckgl_layer` and `custom_layer` appear in scenarios.
- Features that do not work yet, or are planned, appear in the demo's index with a status (stable, limited, planned) linked to the library issue; only working features get an interactive page. (Owner decision, 2026-11-25.)
- Known limits in the library at the time of writing: `sky` cannot render (library issue #14); `terrain_control` has lifecycle faults (#19); deck.gl requires maplibre-gl 5 (#11); the 0.2.0 lifecycle work (style changes, component order, reactive assigns) is in progress.
- The demo follows the library's `main` branch. Source examples use public services that work after a clone; `/ogc` is removed as a page and the separate tile server becomes optional. Structure: a catalogue organised by library family, plus a section of full scenarios that combine components. (Owner decisions, 2026-11-25.)
- Undecided: whether sample data stays synthetic or moves to real datasets.

## Brand Commitments

- Name: MaplibreX, by CountlinkX Solutions. Licence MIT.
- No logo or brand guideline has been supplied.
- Standing visual preference (owner, 2026-11-25): the category standard for component documentation, executed at full craft. The demo should sit alongside shadcn/ui and the MapLibre GL JS documentation; their level of finish is the bar.

## Evidence on Hand

- A catalogue of the 32 components at `/components`, 27 of them with an interactive example, and five scenarios at `/scenarios` (3D terrain, heatmap, buildings, particles, deck.gl). The nine old pages are gone; their URLs redirect to the catalogue and the scenarios.
- Sample data on `/heatmap`, `/buildings` and `/deckgl` is generated, not real; it must be labelled as sample data and never described as real measurements.
- There are no testimonials, usage numbers, benchmarks or customer names; none may be invented.

## Product Principles

1. Show the code. Every example pairs the running map with the template and event handlers that produce it.
2. Tell the truth about status. A feature is shown as working only when it works in the pinned library version; limits link to their issue.
3. One library feature family, one place. A visitor finds a component by the name the library gives it.
4. Follow the library. When the library adds, fixes or changes a feature, the demo's catalogue changes with it.
5. Works after a clone. Pages that need an external service say so and degrade visibly.
