defmodule MaplibrexDemoWeb.Catalogue do
  @moduledoc """
  The single source of truth for what the demo shows: every MaplibreX
  component, grouped by family, with a one-sentence summary, its status and the
  example that demonstrates it; plus the scenarios that combine components and
  the library work the roadmap reports.

  ## Keeping it in step with the library

  The list is written by hand, because summaries and statuses are editorial.
  `MaplibrexDemoWeb.CatalogueTest` fails when `MaplibreX.Components` delegates a
  component this module does not list, or when this module lists one the
  library does not have. Everything structural (attributes, defaults, events)
  is read from the library itself by `MaplibrexDemoWeb.LibraryDocs`.

  ## Statuses

    * `:stable` — works as documented in the library version the demo runs.
    * `:limited` — works, but an open library issue documents a part of its
      behaviour that does not. The issue is linked.
    * `:planned` — cannot be used yet; the linked issue tracks the fix.

  Statuses follow the library's `main` branch, derived from its open issues.
  Problems that affect every component the same way do not change individual
  statuses; the roadmap lists what the library's next release fixes.

  Text is translated when these functions are called, so call them per render
  rather than caching their result across locales.
  """

  use Gettext, backend: MaplibrexDemoWeb.Gettext

  alias MaplibrexDemoWeb.Catalogue.Component
  alias MaplibreX.Components, as: Lib

  @issues_url "https://github.com/CountlinkX-Solutions/maplibrex/issues"

  @family_ids [:map, :markers, :layers, :sources, :controls, :three_d, :advanced]

  @typedoc "A family with its components and computed counts."
  @type family :: %{
          id: atom(),
          label: String.t(),
          components: [Component.t()],
          count: non_neg_integer(),
          statuses: %{
            stable: non_neg_integer(),
            limited: non_neg_integer(),
            planned: non_neg_integer()
          }
        }

  @doc "Every component, in catalogue order (family by family)."
  @spec components() :: [Component.t()]
  def components do
    reactive_control = issue(3, gettext("Changing `position` after mount has no effect."))

    undocumented_events =
      issue(
        28,
        gettext(
          "The events its documentation lists are never sent; `source:added`, `source:error` and `source:removed` arrive instead."
        )
      )

    reactive_custom_control =
      issue(3, gettext("Changes to `position` or `class` after mount are not applied."))

    [
      # Map
      %Component{
        name: :map,
        family: :map,
        module: Lib.Map,
        example: MaplibrexDemoWeb.Examples.MapExample,
        summary:
          gettext(
            "A MapLibre GL JS map whose center, zoom, pitch, bearing and style follow the LiveView's assigns."
          ),
        status: :limited,
        issues: [
          issue(21, gettext("The documented `debug={true}` does not turn on debug logging.")),
          issue(
            25,
            gettext(
              "Without `center`, `zoom` or `style`, the defaults configured for the library are not used."
            )
          ),
          issue(
            26,
            gettext(
              "Changes to `bounds`, `max_bounds`, the zoom and pitch limits, `interactive` or `attribution_control` after mount are not applied."
            )
          )
        ]
      },

      # Markers & popups
      %Component{
        name: :marker,
        family: :markers,
        module: Lib.Marker,
        example: MaplibrexDemoWeb.Examples.MarkerExample,
        summary:
          gettext(
            "A marker at a coordinate, with an optional popup and dragging that reports the new position."
          ),
        status: :limited,
        issues: [
          issue(
            35,
            gettext("Its popup opens on top of the marker instead of above it.")
          ),
          issue(
            36,
            gettext(
              "A popup cannot be added, removed or emptied after mount, only changed to another non-empty text."
            )
          )
        ]
      },
      %Component{
        name: :popup,
        family: :markers,
        module: Lib.Popup,
        example: MaplibrexDemoWeb.Examples.PopupExample,
        summary: gettext("A popup with text or HTML content, placed at a coordinate."),
        status: :limited,
        issues: [
          issue(
            22,
            gettext(
              "The JS helpers `open/1`, `close/1`, `toggle/1` and `set_location/2` do nothing unless the server echoes them back."
            )
          )
        ]
      },

      # Layers
      %Component{
        name: :geojson_layer,
        family: :layers,
        module: Lib.GeoJSONLayer,
        example: MaplibrexDemoWeb.Examples.GeojsonLayerExample,
        summary:
          gettext(
            "Draws GeoJSON data as a fill, line, circle, symbol, heatmap or fill-extrusion layer, with optional clustering and feature events."
          ),
        status: :limited,
        issues: [
          issue(
            22,
            gettext(
              "The JS helpers such as `set_paint_property/3`, `set_data/2`, `show/1` and `hide/1` do nothing unless the server echoes them back."
            )
          )
        ]
      },
      %Component{
        name: :circle_layer,
        family: :layers,
        module: Lib.CircleLayer,
        summary: gettext("Draws points from a source as circles."),
        status: :stable
      },
      %Component{
        name: :line_layer,
        family: :layers,
        module: Lib.LineLayer,
        summary: gettext("Draws lines from a source, such as roads, routes or boundaries."),
        status: :stable
      },
      %Component{
        name: :fill_layer,
        family: :layers,
        module: Lib.FillLayer,
        summary: gettext("Fills polygons from a source."),
        status: :stable
      },
      %Component{
        name: :symbol_layer,
        family: :layers,
        module: Lib.SymbolLayer,
        summary: gettext("Places icons and text labels from a source."),
        status: :stable
      },
      %Component{
        name: :heatmap_layer,
        family: :layers,
        module: Lib.HeatmapLayer,
        summary: gettext("Shows the density of points from a source as a heatmap."),
        status: :stable
      },
      %Component{
        name: :fill_extrusion_layer,
        family: :layers,
        module: Lib.FillExtrusionLayer,
        summary: gettext("Extrudes polygons from a source into 3D shapes, such as buildings."),
        status: :stable
      },
      %Component{
        name: :background_layer,
        family: :layers,
        module: Lib.BackgroundLayer,
        summary: gettext("Paints the map background with a colour or a pattern."),
        status: :stable
      },
      %Component{
        name: :hillshade_layer,
        family: :layers,
        module: Lib.HillshadeLayer,
        example: MaplibrexDemoWeb.Examples.HillshadeLayerExample,
        summary: gettext("Shades relief from a raster DEM source."),
        status: :stable
      },
      %Component{
        name: :raster_layer,
        family: :layers,
        module: Lib.RasterLayer,
        summary: gettext("Shows raster tiles, an image or a video from a source."),
        status: :stable
      },

      # Sources
      %Component{
        name: :vector_tile_source,
        family: :sources,
        module: Lib.VectorTileSource,
        example: MaplibrexDemoWeb.Examples.VectorTileSourceExample,
        summary:
          gettext(
            "Adds vector tiles, from a TileJSON URL or a tile template, for layers to draw."
          ),
        status: :stable
      },
      %Component{
        name: :raster_tile_source,
        family: :sources,
        module: Lib.RasterTileSource,
        example: MaplibrexDemoWeb.Examples.RasterTileSourceExample,
        summary: gettext("Adds raster image tiles for a raster layer to draw."),
        status: :limited,
        issues: [
          issue(
            24,
            gettext("The documented `tms` attribute has no effect; `scheme=\"tms\"` works.")
          )
        ]
      },
      %Component{
        name: :raster_dem_source,
        family: :sources,
        module: Lib.RasterDEMSource,
        example: MaplibrexDemoWeb.Examples.RasterDemSourceExample,
        summary: gettext("Adds elevation tiles for hillshading and 3D terrain."),
        status: :stable
      },
      %Component{
        name: :image_source,
        family: :sources,
        module: Lib.ImageSource,
        summary: gettext("Places an image at four coordinates for a raster layer to draw."),
        status: :limited,
        issues: [undocumented_events]
      },
      %Component{
        name: :video_source,
        family: :sources,
        module: Lib.VideoSource,
        summary: gettext("Places a video at four coordinates for a raster layer to draw."),
        status: :limited,
        issues: [undocumented_events]
      },

      # Controls
      %Component{
        name: :navigation_control,
        family: :controls,
        module: Lib.NavigationControl,
        example: MaplibrexDemoWeb.Examples.NavigationControlExample,
        summary: gettext("Zoom buttons and a compass."),
        status: :limited,
        issues: [reactive_control]
      },
      %Component{
        name: :scale_control,
        family: :controls,
        module: Lib.ScaleControl,
        example: MaplibrexDemoWeb.Examples.ScaleControlExample,
        summary: gettext("A scale bar for the current zoom level."),
        status: :limited,
        issues: [reactive_control]
      },
      %Component{
        name: :fullscreen_control,
        family: :controls,
        module: Lib.FullscreenControl,
        example: MaplibrexDemoWeb.Examples.FullscreenControlExample,
        summary: gettext("A button that shows the map in full screen."),
        status: :limited,
        issues: [reactive_control]
      },
      %Component{
        name: :geolocate_control,
        family: :controls,
        module: Lib.GeolocateControl,
        example: MaplibrexDemoWeb.Examples.GeolocateControlExample,
        summary:
          gettext("A button that centres the map on the user's location, with optional tracking."),
        status: :stable
      },
      %Component{
        name: :attribution_control,
        family: :controls,
        module: Lib.AttributionControl,
        example: MaplibrexDemoWeb.Examples.AttributionControlExample,
        summary: gettext("Shows the attribution of the map's sources."),
        status: :limited,
        issues: [reactive_control]
      },
      %Component{
        name: :terrain_control,
        family: :controls,
        module: Lib.TerrainControl,
        summary: gettext("A button that turns 3D terrain on and off."),
        status: :limited,
        issues: [
          issue(
            19,
            gettext(
              "With `enabled={true}` at mount it fails before the style has loaded, and removing it leaves terrain on."
            )
          )
        ]
      },
      %Component{
        name: :control,
        family: :controls,
        module: Lib.Control,
        example: MaplibrexDemoWeb.Examples.ControlExample,
        summary: gettext("Places your own HEEx content in a corner of the map as a control."),
        status: :limited,
        issues: [reactive_custom_control]
      },
      %Component{
        name: :control_button,
        family: :controls,
        module: Lib.ControlButton,
        example: MaplibrexDemoWeb.Examples.ControlButtonExample,
        summary:
          gettext("A map control button with an icon or your own content, and an active state."),
        status: :stable
      },
      %Component{
        name: :control_group,
        family: :controls,
        module: Lib.ControlGroup,
        example: MaplibrexDemoWeb.Examples.ControlGroupExample,
        summary: gettext("Groups several controls into one map control."),
        status: :limited,
        issues: [reactive_custom_control]
      },
      %Component{
        name: :zoom_range,
        family: :controls,
        module: Lib.ZoomRange,
        example: MaplibrexDemoWeb.Examples.ZoomRangeExample,
        summary: gettext("Shows its content only between a minimum and a maximum zoom level."),
        status: :limited,
        issues: [
          issue(
            3,
            gettext(
              "After `min` or `max` changes, zooming still uses the range it was mounted with."
            )
          )
        ]
      },

      # 3D
      %Component{
        name: :terrain,
        family: :three_d,
        module: Lib.Terrain,
        example: MaplibrexDemoWeb.Examples.TerrainExample,
        summary:
          gettext("Renders 3D terrain from a raster DEM source, with adjustable exaggeration."),
        status: :stable
      },
      %Component{
        name: :sky,
        family: :three_d,
        module: Lib.Sky,
        summary: gettext("Meant to add an atmospheric sky to 3D views; it cannot render yet."),
        status: :planned,
        issues: [
          issue(
            14,
            gettext(
              "It adds a layer type that MapLibre does not have, so no sky appears. The fix changes its attributes."
            )
          )
        ]
      },

      # Advanced
      %Component{
        name: :deckgl_layer,
        family: :advanced,
        module: Lib.DeckGlLayer,
        summary:
          gettext(
            "Renders a deck.gl layer over the map; deck.gl is loaded the first time one mounts."
          ),
        status: :limited,
        issues: [
          issue(11, gettext("Needs maplibre-gl 5; version 6 is not supported yet.")),
          issue(10, gettext("`before_id` is accepted but has no effect."))
        ]
      },
      %Component{
        name: :custom_layer,
        family: :advanced,
        module: Lib.CustomLayer,
        summary:
          gettext("A custom WebGL layer drawn with your own GLSL shaders or a built-in preset."),
        status: :limited,
        issues: [
          issue(
            34,
            gettext(
              "Changes to `uniforms` and its other attributes after mount never reach the browser."
            )
          ),
          issue(27, gettext("After a change of map style it is drawn under the basemap."))
        ]
      }
    ]
  end

  @doc "The families in reading order, each with its components and counts."
  @spec families() :: [family()]
  def families do
    by_family = Enum.group_by(components(), & &1.family)

    for id <- @family_ids do
      members = Map.get(by_family, id, [])

      %{
        id: id,
        label: family_label(id),
        components: members,
        count: length(members),
        statuses: count_statuses(members)
      }
    end
  end

  @doc "The translated name of a family."
  @spec family_label(atom()) :: String.t()
  def family_label(:map), do: gettext("Map")
  def family_label(:markers), do: gettext("Markers & popups")
  def family_label(:layers), do: gettext("Layers")
  def family_label(:sources), do: gettext("Sources")
  def family_label(:controls), do: gettext("Controls")
  def family_label(:three_d), do: gettext("3D")
  def family_label(:advanced), do: gettext("Advanced")

  @doc "How many components have each status."
  @spec status_counts() :: %{
          stable: non_neg_integer(),
          limited: non_neg_integer(),
          planned: non_neg_integer()
        }
  def status_counts, do: count_statuses(components())

  @doc """
  Looks a component up by the name a URL carries.

  Never converts the string to an atom, so unknown names cannot grow the atom
  table.
  """
  @spec fetch(String.t()) :: {:ok, Component.t()} | :error
  def fetch(name) when is_binary(name) do
    case Enum.find(components(), &(Atom.to_string(&1.name) == name)) do
      nil -> :error
      component -> {:ok, component}
    end
  end

  @doc "Looks a component up by its atom name; raises if it is not catalogued."
  @spec fetch!(atom()) :: Component.t()
  def fetch!(name) when is_atom(name) do
    Enum.find(components(), &(&1.name == name)) ||
      raise ArgumentError, "#{inspect(name)} is not in the catalogue"
  end

  @doc """
  The components whose name contains the query.

  Case is ignored and spaces or hyphens count as underscores, so
  `"tile source"` finds `vector_tile_source`. A blank query returns everything.
  """
  @spec search(String.t()) :: [Component.t()]
  def search(query) when is_binary(query) do
    needle =
      query
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[\s-]+/, "_")

    if needle == "" do
      components()
    else
      Enum.filter(components(), &String.contains?(Atom.to_string(&1.name), needle))
    end
  end

  @doc "The components before and after `name` in catalogue order."
  @spec neighbours(atom()) :: {Component.t() | nil, Component.t() | nil}
  def neighbours(name) when is_atom(name) do
    all = components()
    index = Enum.find_index(all, &(&1.name == name))

    previous = if index > 0, do: Enum.at(all, index - 1)
    {previous, Enum.at(all, index + 1)}
  end

  @doc """
  The scenarios that combine several components, each a page at
  `/scenarios/:id` that runs `module` above its source.

  `sample_data` is true when the scenario draws data generated for the demo
  rather than real measurements. `notes` are library issues the scenario
  depends on, each with a one-sentence note.
  """
  @spec scenarios() :: [map()]
  def scenarios do
    [
      %{
        id: :terrain_3d,
        title: gettext("3D terrain flight"),
        summary:
          gettext(
            "Hillshading and 3D terrain from a public elevation service, with the exaggeration set from the server and camera flights between mountain ranges."
          ),
        components: [
          :map,
          :raster_dem_source,
          :hillshade_layer,
          :terrain,
          :navigation_control
        ],
        sample_data: false,
        module: MaplibrexDemoWeb.Scenarios.TerrainScenario,
        notes: []
      },
      %{
        id: :heatmap,
        title: gettext("Earthquake-style heatmap"),
        summary:
          gettext(
            "Sample points around six seismic zones of the United States, drawn as a heatmap whose radius, intensity and opacity are set from the server."
          ),
        components: [:map, :geojson_layer, :navigation_control],
        sample_data: true,
        module: MaplibrexDemoWeb.Scenarios.HeatmapScenario,
        notes: []
      },
      %{
        id: :buildings,
        title: gettext("Extruded buildings"),
        summary:
          gettext(
            "A synthetic grid of blocks extruded in 3D, whose height, opacity and colours are set from the server. They are not real buildings."
          ),
        components: [:map, :geojson_layer, :navigation_control],
        sample_data: true,
        module: MaplibrexDemoWeb.Scenarios.BuildingsScenario,
        notes: []
      },
      %{
        id: :particles,
        title: gettext("WebGL particles"),
        summary:
          gettext(
            "1,000 particles drawn by a custom WebGL layer with its own shaders, whose colour, speed, turbulence and direction are uniforms set from the server."
          ),
        components: [:map, :custom_layer, :navigation_control],
        sample_data: false,
        module: MaplibrexDemoWeb.Scenarios.ParticlesScenario,
        notes: []
      },
      %{
        id: :deckgl,
        title: gettext("deck.gl layers"),
        summary:
          gettext(
            "deck.gl arc, hexagon and scatterplot layers drawn over the map from sample data, one at a time, with clicks coming back to the server."
          ),
        components: [:map, :deckgl_layer, :navigation_control],
        sample_data: true,
        module: MaplibrexDemoWeb.Scenarios.DeckglScenario,
        notes: [
          issue(
            11,
            gettext(
              "deck.gl needs maplibre-gl 5, which this demo pins; MaplibreX does not support it on maplibre-gl 6 yet."
            )
          )
        ]
      }
    ]
  end

  @doc """
  Looks a scenario up by the id a URL carries.

  Never converts the string to an atom, so unknown ids cannot grow the atom
  table.
  """
  @spec fetch_scenario(String.t()) :: {:ok, map()} | :error
  def fetch_scenario(id) when is_binary(id) do
    case Enum.find(scenarios(), &(Atom.to_string(&1.id) == id)) do
      nil -> :error
      scenario -> {:ok, scenario}
    end
  end

  @doc "The scenarios before and after `id`."
  @spec scenario_neighbours(atom()) :: {map() | nil, map() | nil}
  def scenario_neighbours(id) when is_atom(id) do
    all = scenarios()
    index = Enum.find_index(all, &(&1.id == id))

    previous = if index > 0, do: Enum.at(all, index - 1)
    {previous, Enum.at(all, index + 1)}
  end

  @doc """
  The library's next release and what it fixes, each item with the issues
  it closes (#3 only for layers, sources and terrain).

  `state` is `:merged` while the release is on the library's `main` branch
  but not yet published on Hex; the demo follows `main`, so the statuses
  above already reflect it. Source: the library's 0.2.0 changelog and its
  closed issues. No dates: the library has not announced one.
  """
  @spec next_release() :: %{
          version: String.t(),
          state: :merged,
          items: [%{issues: [pos_integer()], text: String.t()}]
        }
  def next_release do
    %{
      version: "0.2.0",
      state: :merged,
      items: [
        %{
          issues: [3],
          text:
            gettext(
              "Layers, sources and terrain apply changes to their assigns after mount. Controls do not yet."
            )
        },
        %{
          issues: [4, 16],
          text: gettext("Sources, layers and terrain survive a change of map style.")
        },
        %{
          issues: [5, 12, 17],
          text:
            gettext(
              "A layer, source or terrain appears whatever its place in the template and whenever it mounts."
            )
        },
        %{
          issues: [15],
          text:
            gettext("Components placed inside `<.map>` update like the ones placed next to it.")
        },
        %{
          issues: [18],
          text: gettext("Removing a source together with its layers leaves nothing on the map.")
        },
        %{
          issues: [20],
          text: gettext("`layer:source_loaded` is sent once the layer's source has loaded.")
        }
      ]
    }
  end

  @doc """
  The components `MaplibreX.Components` delegates, as `%{name => module}`.

  Read from the library's documentation chunk, where `defdelegate` records its
  target. This is what the catalogue is checked against.
  """
  @spec library_components() :: %{atom() => module()}
  def library_components do
    case Code.fetch_docs(Lib) do
      {:docs_v1, _, _, _, _, _, docs} ->
        for {{:function, name, 1}, _, _, _, %{delegate_to: {module, _fun, 1}}} <- docs,
            into: %{},
            do: {name, module}

      {:error, reason} ->
        raise "cannot read the documentation of MaplibreX.Components: #{inspect(reason)}"
    end
  end

  @doc "The URL of a library issue."
  @spec issue_url(pos_integer()) :: String.t()
  def issue_url(number), do: "#{@issues_url}/#{number}"

  @doc "The URL of the library's open issue list."
  @spec issues_url() :: String.t()
  def issues_url, do: @issues_url

  defp issue(number, note), do: %{number: number, note: note}

  defp count_statuses(components) do
    base = %{stable: 0, limited: 0, planned: 0}

    Enum.reduce(components, base, fn %{status: status}, acc ->
      Map.update!(acc, status, &(&1 + 1))
    end)
  end
end
