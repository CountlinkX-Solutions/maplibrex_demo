---
version: 1
slug: "lib-maplibrex-demo-web"
primary_target: "lib/maplibrex_demo_web"
related_targets: []
---

# Surface brief — demo shell, catalogue and component pages

Scope: the whole demo application (overview, component pages, scenarios, roadmap). Visitor mode: Read, with an interactive preview on each page.

Audience and job: an Elixir developer evaluating MaplibreX locally; find a component, see it work, copy its code, learn its status.
Content: the 32 library components grouped by family, each with summary, live example, the example's real source, events and attributes; scenarios combining components; status (stable, limited, planned) linked to library issues.
Constraints: Phoenix 1.8 / LiveView 1.2 / Tailwind 4 and the repository's AGENTS.md; English and Spanish interface copy; works after a clone; basemap attribution stays visible; sample data labelled as sample.
Memorable moment: the code under the map is the code that is running, and changing a control changes both the map and the highlighted assign.
Unresolved: real versus synthetic sample data.

## Direction contract

THESIS: The demo is the library's component reference that runs: one page per component, the live map above the exact code that produced it. It refuses the full-bleed map under a floating glass panel that the demo had before.

OWN-WORLD: White ground, cool grey sidebar and top bar hairlines, ink near-black with a blue cast, one Elixir-purple accent reserved for the current location and for things that can be pressed. Lato for text, JetBrains Mono for code and identifiers. One-pixel rules, 6 to 8 px radii, dark code blocks, status shown as a mark plus a word. Light and dark themes share the same roles.

STORY: The visitor sees how much the library covers, opens a component, watches it work, copies the code and knows whether it is stable, limited or planned.

FIRST VIEWPORT: A 60 px top bar with the wordmark, the library version, Components, Scenarios, Roadmap and search. A 280 px sidebar tree grouped by family, the current item filled purple. In the main column: the component name at about 36 px with its status badge, a one-sentence lead, the tab row Preview, HEEx, Events, Attributes, a map preview about 360 px tall, and the code block directly beneath it.

FORM: The category standard, chosen by the owner as the standing exit of the direction round; benchmarks shadcn/ui and the MapLibre GL JS documentation. seed:aa4c8b15b9198716

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
