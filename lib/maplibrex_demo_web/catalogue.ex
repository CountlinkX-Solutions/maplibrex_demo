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

  Problems that affect every component the same way (style changes, the order
  components mount in) do not change individual statuses; the roadmap lists
  them as the library's next release work.

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
    reactive_layer =
      issue(
        3,
        gettext(
          "Changes to `paint`, `layout`, `filter` or the zoom range after mount are not applied."
        )
      )

    reactive_source =
      issue(3, gettext("Changes to a source's attributes after mount are not applied."))

    reactive_control = issue(3, gettext("Changing `position` after mount has no effect."))

    [
      # Map
      %Component{
        name: :map,
        family: :map,
        module: Lib.Map,
        summary:
          gettext(
            "A MapLibre GL JS map whose center, zoom, pitch, bearing and style follow the LiveView's assigns."
          ),
        status: :limited,
        issues: [
          issue(
            16,
            gettext(
              "A style given as a map rather than a URL is applied again on every update, which removes component layers."
            )
          ),
          issue(21, gettext("The documented `debug={true}` does not turn on debug logging."))
        ]
      },

      # Markers & popups
      %Component{
        name: :marker,
        family: :markers,
        module: Lib.Marker,
        summary:
          gettext(
            "A marker at a coordinate, with an optional popup and dragging that reports the new position."
          ),
        status: :stable
      },
      %Component{
        name: :popup,
        family: :markers,
        module: Lib.Popup,
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
          ),
          issue(20, gettext("`layer:source_loaded` is often never sent."))
        ]
      },
      %Component{
        name: :circle_layer,
        family: :layers,
        module: Lib.CircleLayer,
        summary: gettext("Draws points from a source as circles."),
        status: :limited,
        issues: [reactive_layer]
      },
      %Component{
        name: :line_layer,
        family: :layers,
        module: Lib.LineLayer,
        summary: gettext("Draws lines from a source, such as roads, routes or boundaries."),
        status: :limited,
        issues: [reactive_layer]
      },
      %Component{
        name: :fill_layer,
        family: :layers,
        module: Lib.FillLayer,
        summary: gettext("Fills polygons from a source."),
        status: :limited,
        issues: [reactive_layer]
      },
      %Component{
        name: :symbol_layer,
        family: :layers,
        module: Lib.SymbolLayer,
        summary: gettext("Places icons and text labels from a source."),
        status: :limited,
        issues: [reactive_layer]
      },
      %Component{
        name: :heatmap_layer,
        family: :layers,
        module: Lib.HeatmapLayer,
        summary: gettext("Shows the density of points from a source as a heatmap."),
        status: :limited,
        issues: [reactive_layer]
      },
      %Component{
        name: :fill_extrusion_layer,
        family: :layers,
        module: Lib.FillExtrusionLayer,
        summary: gettext("Extrudes polygons from a source into 3D shapes, such as buildings."),
        status: :limited,
        issues: [reactive_layer]
      },
      %Component{
        name: :background_layer,
        family: :layers,
        module: Lib.BackgroundLayer,
        summary: gettext("Paints the map background with a colour or a pattern."),
        status: :limited,
        issues: [reactive_layer]
      },
      %Component{
        name: :hillshade_layer,
        family: :layers,
        module: Lib.HillshadeLayer,
        summary: gettext("Shades relief from a raster DEM source."),
        status: :limited,
        issues: [reactive_layer]
      },
      %Component{
        name: :raster_layer,
        family: :layers,
        module: Lib.RasterLayer,
        summary: gettext("Shows raster tiles, an image or a video from a source."),
        status: :limited,
        issues: [reactive_layer]
      },

      # Sources
      %Component{
        name: :vector_tile_source,
        family: :sources,
        module: Lib.VectorTileSource,
        summary:
          gettext(
            "Adds vector tiles, from a TileJSON URL or a tile template, for layers to draw."
          ),
        status: :limited,
        issues: [reactive_source]
      },
      %Component{
        name: :raster_tile_source,
        family: :sources,
        module: Lib.RasterTileSource,
        summary: gettext("Adds raster image tiles for a raster layer to draw."),
        status: :limited,
        issues: [reactive_source]
      },
      %Component{
        name: :raster_dem_source,
        family: :sources,
        module: Lib.RasterDEMSource,
        summary: gettext("Adds elevation tiles for hillshading and 3D terrain."),
        status: :limited,
        issues: [reactive_source]
      },
      %Component{
        name: :image_source,
        family: :sources,
        module: Lib.ImageSource,
        summary: gettext("Places an image at four coordinates for a raster layer to draw."),
        status: :limited,
        issues: [reactive_source]
      },
      %Component{
        name: :video_source,
        family: :sources,
        module: Lib.VideoSource,
        summary: gettext("Places a video at four coordinates for a raster layer to draw."),
        status: :limited,
        issues: [reactive_source]
      },

      # Controls
      %Component{
        name: :navigation_control,
        family: :controls,
        module: Lib.NavigationControl,
        summary: gettext("Zoom buttons and a compass."),
        status: :limited,
        issues: [reactive_control]
      },
      %Component{
        name: :scale_control,
        family: :controls,
        module: Lib.ScaleControl,
        summary: gettext("A scale bar for the current zoom level."),
        status: :limited,
        issues: [reactive_control]
      },
      %Component{
        name: :fullscreen_control,
        family: :controls,
        module: Lib.FullscreenControl,
        summary: gettext("A button that shows the map in full screen."),
        status: :limited,
        issues: [reactive_control]
      },
      %Component{
        name: :geolocate_control,
        family: :controls,
        module: Lib.GeolocateControl,
        summary:
          gettext("A button that centres the map on the user's location, with optional tracking."),
        status: :stable
      },
      %Component{
        name: :attribution_control,
        family: :controls,
        module: Lib.AttributionControl,
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
        summary: gettext("Places your own HEEx content in a corner of the map as a control."),
        status: :stable
      },
      %Component{
        name: :control_button,
        family: :controls,
        module: Lib.ControlButton,
        summary:
          gettext("A map control button with an icon or your own content, and an active state."),
        status: :stable
      },
      %Component{
        name: :control_group,
        family: :controls,
        module: Lib.ControlGroup,
        summary: gettext("Groups several controls into one map control."),
        status: :stable
      },
      %Component{
        name: :zoom_range,
        family: :controls,
        module: Lib.ZoomRange,
        summary: gettext("Shows its content only between a minimum and a maximum zoom level."),
        status: :stable
      },

      # 3D
      %Component{
        name: :terrain,
        family: :three_d,
        module: Lib.Terrain,
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
        status: :stable
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
  The scenarios that combine several components.

  None has been rebuilt in the catalogue yet, so each is `:coming` and points
  at the page that still shows it (`legacy_path`). `sample_data` is true when
  that page draws generated data rather than real measurements.
  """
  @spec scenarios() :: [map()]
  def scenarios do
    [
      %{
        id: :terrain_3d,
        title: gettext("3D terrain"),
        summary:
          gettext(
            "Elevation from a public DEM drawn as hillshading and 3D terrain, with the exaggeration set from the server."
          ),
        components: [:map, :raster_dem_source, :hillshade_layer, :terrain, :navigation_control],
        sample_data: false,
        status: :coming,
        legacy_path: "/terrain"
      },
      %{
        id: :heatmap,
        title: gettext("Heatmap"),
        summary:
          gettext("A heatmap whose radius, intensity and opacity are set from the server."),
        components: [:map, :geojson_layer, :navigation_control],
        sample_data: true,
        status: :coming,
        legacy_path: "/heatmap"
      },
      %{
        id: :buildings,
        title: gettext("3D buildings"),
        summary:
          gettext(
            "Extruded building footprints whose height, opacity and colours are set from the server."
          ),
        components: [:map, :geojson_layer, :navigation_control],
        sample_data: true,
        status: :coming,
        legacy_path: "/buildings"
      },
      %{
        id: :particles,
        title: gettext("WebGL particles"),
        summary:
          gettext("Animated particles drawn by a custom WebGL layer with its own shaders."),
        components: [:map, :custom_layer, :navigation_control],
        sample_data: false,
        status: :coming,
        legacy_path: "/particles"
      },
      %{
        id: :deckgl,
        title: gettext("deck.gl layers"),
        summary: gettext("deck.gl arc, hexagon and scatterplot layers drawn over the map."),
        components: [:map, :deckgl_layer, :navigation_control],
        sample_data: true,
        status: :coming,
        legacy_path: "/deckgl"
      }
    ]
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
