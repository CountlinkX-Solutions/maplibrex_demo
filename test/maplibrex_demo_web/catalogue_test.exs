defmodule MaplibrexDemoWeb.CatalogueTest do
  use ExUnit.Case, async: true

  alias MaplibrexDemoWeb.Catalogue
  alias MaplibrexDemoWeb.Catalogue.Component

  describe "sync with the library" do
    # The catalogue is written by hand, so this is what keeps it honest: every
    # component MaplibreX.Components delegates must be listed, and every listed
    # component must exist in the library.
    test "lists exactly the components MaplibreX.Components delegates" do
      library = Catalogue.library_components()
      catalogued = Map.new(Catalogue.components(), &{&1.name, &1.module})

      missing = Map.keys(library) -- Map.keys(catalogued)
      unknown = Map.keys(catalogued) -- Map.keys(library)

      assert missing == [], "components missing from the catalogue: #{inspect(missing)}"
      assert unknown == [], "catalogued components the library does not have: #{inspect(unknown)}"
    end

    test "points every component at the module the library delegates to" do
      library = Catalogue.library_components()

      for %Component{name: name, module: module} <- Catalogue.components() do
        assert library[name] == module,
               "#{name} is catalogued as #{inspect(module)}, the library delegates to #{inspect(library[name])}"
      end
    end

    test "every catalogued module documents its component with attrs" do
      for %Component{name: name, module: module} <- Catalogue.components() do
        assert %{^name => %{attrs: [_ | _]}} = module.__components__()
      end
    end
  end

  describe "components/0" do
    test "holds 32 components with unique names" do
      names = Enum.map(Catalogue.components(), & &1.name)

      assert length(names) == 32
      assert names == Enum.uniq(names)
    end

    test "gives every component a family, a summary and a known status" do
      family_ids = Enum.map(Catalogue.families(), & &1.id)

      for component <- Catalogue.components() do
        assert component.family in family_ids
        assert is_binary(component.summary) and component.summary != ""
        assert component.status in [:stable, :limited, :planned]
      end
    end

    test "justifies every non-stable status with at least one library issue" do
      for %Component{status: status} = component <- Catalogue.components(), status != :stable do
        assert [%{number: number, note: note} | _] = component.issues,
               "#{component.name} is #{status} without an issue"

        assert is_integer(number) and number > 0
        assert is_binary(note) and note != ""
      end
    end

    # Statuses on the library's main branch (0.2.0, published on Hex),
    # derived from its open issues.
    @limited %{
      map: [21, 25, 26],
      marker: [35, 36],
      popup: [37, 22],
      geojson_layer: [22],
      raster_tile_source: [24],
      image_source: [28],
      video_source: [28],
      navigation_control: [3],
      scale_control: [3],
      fullscreen_control: [3],
      attribution_control: [3],
      geolocate_control: [40],
      terrain_control: [19],
      control: [3],
      control_group: [38, 39, 3],
      zoom_range: [3],
      deckgl_layer: [11, 10],
      custom_layer: [34, 27]
    }

    test "records the statuses the library's open issues justify" do
      assert %{status: :planned, issues: [%{number: 14}]} = Catalogue.fetch!(:sky)

      for {name, numbers} <- @limited do
        component = Catalogue.fetch!(name)

        assert component.status == :limited, "#{name} is #{component.status}"

        assert Enum.map(component.issues, & &1.number) == numbers,
               "#{name} cites the wrong issues"
      end
    end

    test "marks stable what 0.2.0 fixed and no open issue limits" do
      for name <- ~w(circle_layer line_layer fill_layer symbol_layer heatmap_layer
                     fill_extrusion_layer background_layer hillshade_layer raster_layer
                     vector_tile_source raster_dem_source terrain control_button)a do
        assert %{status: :stable, issues: []} = Catalogue.fetch!(name)
      end
    end

    test "cites no issue the library has closed" do
      closed = [2, 4, 5, 6, 7, 8, 9, 12, 15, 16, 17, 18, 20]

      for component <- Catalogue.components(), %{number: number} <- component.issues do
        refute number in closed, "#{component.name} cites closed issue ##{number}"
      end
    end
  end

  describe "examples" do
    test "the map has the reference example" do
      assert Catalogue.fetch!(:map).example == MaplibrexDemoWeb.Examples.MapExample
    end

    test "the components migrated from the old pages have their examples" do
      examples = %{
        marker: MaplibrexDemoWeb.Examples.MarkerExample,
        geojson_layer: MaplibrexDemoWeb.Examples.GeojsonLayerExample,
        navigation_control: MaplibrexDemoWeb.Examples.NavigationControlExample,
        scale_control: MaplibrexDemoWeb.Examples.ScaleControlExample,
        fullscreen_control: MaplibrexDemoWeb.Examples.FullscreenControlExample,
        raster_dem_source: MaplibrexDemoWeb.Examples.RasterDemSourceExample,
        hillshade_layer: MaplibrexDemoWeb.Examples.HillshadeLayerExample,
        terrain: MaplibrexDemoWeb.Examples.TerrainExample
      }

      for {name, example} <- examples do
        assert Catalogue.fetch!(name).example == example
      end
    end

    test "the components whose examples came with the 0.2.0 statuses have them" do
      examples = %{
        popup: MaplibrexDemoWeb.Examples.PopupExample,
        attribution_control: MaplibrexDemoWeb.Examples.AttributionControlExample,
        geolocate_control: MaplibrexDemoWeb.Examples.GeolocateControlExample,
        control: MaplibrexDemoWeb.Examples.ControlExample,
        control_button: MaplibrexDemoWeb.Examples.ControlButtonExample,
        control_group: MaplibrexDemoWeb.Examples.ControlGroupExample,
        zoom_range: MaplibrexDemoWeb.Examples.ZoomRangeExample,
        vector_tile_source: MaplibrexDemoWeb.Examples.VectorTileSourceExample,
        raster_tile_source: MaplibrexDemoWeb.Examples.RasterTileSourceExample,
        image_source: MaplibrexDemoWeb.Examples.ImageSourceExample,
        circle_layer: MaplibrexDemoWeb.Examples.CircleLayerExample,
        line_layer: MaplibrexDemoWeb.Examples.LineLayerExample,
        fill_layer: MaplibrexDemoWeb.Examples.FillLayerExample,
        symbol_layer: MaplibrexDemoWeb.Examples.SymbolLayerExample,
        heatmap_layer: MaplibrexDemoWeb.Examples.HeatmapLayerExample,
        fill_extrusion_layer: MaplibrexDemoWeb.Examples.FillExtrusionLayerExample,
        background_layer: MaplibrexDemoWeb.Examples.BackgroundLayerExample,
        raster_layer: MaplibrexDemoWeb.Examples.RasterLayerExample
      }

      for {name, example} <- examples do
        assert Catalogue.fetch!(name).example == example, "#{name} has no example"
      end
    end

    test "says why a working component has no example when its status does not" do
      assert %{example: nil, example_note: note} = Catalogue.fetch!(:video_source)
      assert note =~ "video"

      for %Component{example: example, example_note: note} <- Catalogue.components(), example do
        assert note == nil
      end
    end

    test "every example is a LiveView with its source on hand" do
      for %Component{example: example} <- Catalogue.components(), example do
        assert Code.ensure_loaded?(example)
        assert function_exported?(example, :mount, 3)
        assert [_ | _] = MaplibrexDemoWeb.Examples.Sources.files(example)
      end
    end
  end

  describe "families/0" do
    test "lists the seven families in reading order" do
      assert Enum.map(Catalogue.families(), & &1.id) ==
               [:map, :markers, :layers, :sources, :controls, :three_d, :advanced]
    end

    test "counts the components of each family and their statuses" do
      layers = Enum.find(Catalogue.families(), &(&1.id == :layers))

      assert layers.count == 10
      assert layers.statuses == %{stable: 9, limited: 1, planned: 0}
      assert Enum.map(layers.components, & &1.name) |> hd() == :geojson_layer

      assert Enum.sum(Enum.map(Catalogue.families(), & &1.count)) == 32
    end
  end

  describe "fetch/1" do
    test "finds a component by its string name" do
      assert {:ok, %Component{name: :marker}} = Catalogue.fetch("marker")
    end

    test "does not create atoms for unknown names" do
      assert Catalogue.fetch("no_such_component_xyz") == :error
    end
  end

  describe "status_counts/0" do
    test "adds up to the size of the catalogue" do
      counts = Catalogue.status_counts()

      assert counts.stable + counts.limited + counts.planned == 32
      assert counts.planned >= 1
    end
  end

  describe "search/1" do
    test "matches on part of the name, ignoring case" do
      assert Enum.map(Catalogue.search("CIRCLE"), & &1.name) == [:circle_layer]
    end

    test "treats spaces as underscores" do
      assert Enum.map(Catalogue.search("tile source"), & &1.name) ==
               [:vector_tile_source, :raster_tile_source]
    end

    test "returns everything for a blank query" do
      assert length(Catalogue.search("  ")) == 32
    end

    test "returns nothing when no name matches" do
      assert Catalogue.search("zzz") == []
    end
  end

  describe "neighbours/1" do
    test "returns the previous and next component in catalogue order" do
      assert {nil, %Component{name: :marker}} = Catalogue.neighbours(:map)
      assert {%Component{name: :map}, %Component{name: :popup}} = Catalogue.neighbours(:marker)
      assert {%Component{name: :deckgl_layer}, nil} = Catalogue.neighbours(:custom_layer)
    end
  end

  describe "scenarios/0" do
    test "names only catalogued components" do
      names = MapSet.new(Catalogue.components(), & &1.name)

      for scenario <- Catalogue.scenarios() do
        assert Enum.all?(scenario.components, &MapSet.member?(names, &1))
      end
    end

    test "every rebuilt scenario is a LiveView with its source on hand" do
      for %{module: module} <- Catalogue.scenarios(), module do
        assert Code.ensure_loaded?(module)
        assert function_exported?(module, :mount, 3)
        assert [_template, _module] = MaplibrexDemoWeb.Examples.Sources.files(module)
      end
    end

    test "every scenario of the old pages is rebuilt" do
      assert Enum.map(Catalogue.scenarios(), & &1.id) ==
               [:terrain_3d, :heatmap, :buildings, :particles, :deckgl]

      for scenario <- Catalogue.scenarios() do
        assert scenario.module, "#{scenario.id} has no page"
        refute Map.has_key?(scenario, :legacy_path)
      end
    end
  end

  describe "next_release/0" do
    test "reports 0.2.0 as published on Hex, with the issues it fixes" do
      release = Catalogue.next_release()

      assert release.version == "0.2.0"
      assert release.state == :published

      assert release.items |> Enum.flat_map(& &1.issues) |> Enum.sort() ==
               [3, 4, 5, 12, 15, 16, 17, 18, 20]
    end

    test "reports the release as published once Hex has it" do
      assert Catalogue.next_release("0.1.1").state == :merged
      assert Catalogue.next_release("0.2.0").state == :published
    end
  end

  describe "hex_release/0 and unreleased?/2" do
    test "the Hex release is a version" do
      assert {:ok, _version} = Version.parse(Catalogue.hex_release())
    end

    test "a version ahead of the Hex release is unreleased" do
      assert Catalogue.unreleased?("0.2.0", "0.1.1")
      refute Catalogue.unreleased?("0.2.0", "0.2.0")
      refute Catalogue.unreleased?("0.1.1", "0.2.0")
    end

    test "a version that cannot be read is not called unreleased" do
      refute Catalogue.unreleased?("?", "0.1.1")
    end

    test "compares with the Hex release by default" do
      assert Catalogue.unreleased?("999.0.0")
      refute Catalogue.unreleased?(Catalogue.hex_release())
    end
  end

  describe "fetch_scenario/1" do
    test "finds a scenario by its string id" do
      assert {:ok, %{id: :terrain_3d}} = Catalogue.fetch_scenario("terrain_3d")
    end

    test "does not create atoms for unknown ids" do
      assert Catalogue.fetch_scenario("no_such_scenario_xyz") == :error
    end
  end
end
