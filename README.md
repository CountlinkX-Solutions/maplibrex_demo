# MaplibreX Demo

A Phoenix LiveView application that documents
[MaplibreX](https://github.com/CountlinkX-Solutions/maplibrex), the library of
MapLibre GL JS components for Phoenix LiveView, by running it. Every component
the library exports is listed with a status (stable, limited or planned) linked
to the library issue that explains it. Each one that works has an example: the
running map next to the HEEx and Elixir source that produce it. Scenarios
combine several components into one map.

It runs locally; there is no public deployment.

## Coverage

At the time of writing (MaplibreX 0.2.1, library `main` at `c84b7f9`), the catalogue lists all
32 components of `MaplibreX.Components`:

- 27 have an interactive example of their own.
- `deckgl_layer` and `custom_layer` run in scenarios only.
- `sky` (planned, #14), `terrain_control` (limited, #19) and `video_source`
  (no openly licensed video lines up with four points on a map) have no
  running example.
- Statuses: 15 stable, 16 limited, 1 planned.

These numbers are computed from the catalogue, and the app shows the current
ones on `/` and `/roadmap`; trust the app over this list.

## Running it

You need Elixir 1.15 or later, Node.js with npm, and network access: the
basemaps, elevation tiles and imagery come from public services
(OpenFreeMap, MapLibre's demo tiles, Mapterhorn, NASA GIBS).

```bash
git clone https://github.com/CountlinkX-Solutions/maplibrex_demo.git
cd maplibrex_demo
mix setup
mix phx.server
```

Then open <http://localhost:4003> (set `PORT` to use another port).

`mix setup` fetches the Elixir dependencies, installs the JavaScript ones into
`assets/node_modules` (`maplibre-gl`, the `@deck.gl/*` packages and the
MaplibreX package itself), and builds the assets.

maplibre-gl is pinned to version 5 because `<.deckgl_layer>` needs it
(library issue #11). MaplibreX supports version 6 for every other component;
with esbuild, version 6 also needs its worker files served next to the bundle
(step 4 of the library README's installation).

## Pages

| Route | What it shows |
| --- | --- |
| `/` | What MaplibreX is, how to install it, a minimal map, and the components counted by family and status |
| `/components` | Every component by family, with its status |
| `/components/:name` | One component: Preview, HEEx (`?tab=heex`), Events (`?tab=events`) and Attributes (`?tab=attributes`) |
| `/scenarios` | The scenarios |
| `/scenarios/:id` | One scenario above its source: `terrain_3d`, `heatmap`, `buildings`, `particles`, `deckgl` |
| `/roadmap` | Every limited or planned component with its issues, and what MaplibreX 0.2.0 fixes |

The pages of earlier versions of the demo (`/map`, `/markers`, `/terrain`,
`/heatmap`, `/buildings`, `/particles`, `/deckgl`, `/tiles`, `/ogc`) redirect
permanently to the catalogue or the matching scenario.

The interface is in English and Spanish. The language switch is in the top bar,
or in the navigation drawer on narrow screens; the choice is kept in the
session. Next to it, the theme switch chooses light, dark or the system's
setting.

## Which version of MaplibreX it runs

The demo follows the library's `main` branch, not a Hex release, and its
statuses describe `main`. `mix.exs` names the branch and `mix.lock` holds the
commit. To move to the latest commit on `main`, run without `MAPLIBREX_PATH`:

```bash
mix deps.update maplibrex
```

The version in the top bar is the one the running application loaded.

## Running against a local MaplibreX checkout

Set `MAPLIBREX_PATH` to a checkout of the library, relative to this directory
or absolute. The Elixir dependency then compiles from that checkout, and the
JavaScript hooks and the stylesheet are bundled from it too:

```bash
git clone https://github.com/CountlinkX-Solutions/maplibrex.git ../maplibrex

MAPLIBREX_PATH=../maplibrex mix setup
MAPLIBREX_PATH=../maplibrex mix phx.server
```

Both sides use one checkout. esbuild and Tailwind resolve MaplibreX through
the npm link `assets/node_modules/maplibrex`; `mix assets.build`,
`mix assets.deploy` and `mix phx.server` point that link at `MAPLIBREX_PATH`,
or at `deps/maplibrex` when it is unset, before they build. A `deps/maplibrex`
left from running without the variable is not read. The mechanism is described
in `config/config.exs` and `mix.exs`.

While developing the library:

- After changing its TypeScript, rebuild its bundle in the library
  (`mix assets.build`, or `mix assets.watch`); the demo's esbuild watcher
  picks up the new bundle.
- After changing its Elixir code, restart the demo's server: the code reloader
  recompiles only this application, not its dependencies.

## Tests

```bash
MAPLIBREX_PATH=../maplibrex mix test   # against a local checkout
mix test                               # against the locked commit
mix precommit
```

Run `mix precommit` without `MAPLIBREX_PATH`. It runs `mix deps.unlock --unused`,
and with a path dependency that would drop MaplibreX from `mix.lock`.

## How the catalogue stays in step with the library

`MaplibrexDemoWeb.Catalogue` (`lib/maplibrex_demo_web/catalogue.ex`) is the one
list of what the demo shows: each component's family, summary, status, issues
and example. Summaries and statuses are written by hand; the rest is checked
against or read from the library:

- `test/maplibrex_demo_web/catalogue_test.exs` fails when
  `MaplibreX.Components` delegates a component the catalogue does not list,
  when the catalogue lists one the library does not have, or when a component
  points at the wrong module.
- The Attributes tab is generated from each component's `__components__/0`
  metadata, and the Events tab from the "Events" section of its documentation
  (`MaplibrexDemoWeb.LibraryDocs`), so neither can drift from the library.
- The HEEx tab and the scenario pages show the example's own source files,
  read at compile time (`MaplibrexDemoWeb.Examples.Sources`): what is shown is
  what runs.
- A status other than stable must cite at least one library issue, and the
  tests keep a list of the library's closed issues that no component may
  cite. Add an issue to that list when the library closes it.

When the library changes, update the statuses and issues in the catalogue and
its tests together.

## Adding an example

An example is a LiveView of its own in `lib/maplibrex_demo_web/examples/`,
named after the component:

1. `foo_example.ex` with `use MaplibrexDemoWeb, :live_view`,
   `import MaplibreX.Components`,
   `import MaplibrexDemoWeb.Examples.ExampleComponents` and
   `on_mount MaplibrexDemoWeb.Examples.Plumbing` (it applies the page's locale
   and copies the library's events to the Events tab; an application needs
   none of it).
2. `foo_example.html.heex` next to it, with the map inside `<.example_frame>`
   and `class="h-full w-full"` on `<.map>`. Give every element a unique DOM id.
3. `example: MaplibrexDemoWeb.Examples.FooExample` on the component's entry in
   the catalogue.
4. `test/maplibrex_demo_web/examples/foo_example_test.exs`, mounting it with
   `live_isolated/3` and sending the library's events with `render_hook/3`.
5. Spanish for any new interface text: `mix gettext.extract --merge`, then
   translate the new entries in `priv/gettext/es/LC_MESSAGES/default.po`.

The existing examples, such as `popup_example.ex`, follow this pattern. A
scenario is built the same way in `lib/maplibrex_demo_web/scenarios/` and
listed in `Catalogue.scenarios/0`.

## License

MIT.
