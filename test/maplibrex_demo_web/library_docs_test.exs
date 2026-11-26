defmodule MaplibrexDemoWeb.LibraryDocsTest do
  use ExUnit.Case, async: true

  alias MaplibrexDemoWeb.{Catalogue, LibraryDocs}

  describe "attributes/1" do
    test "lists every attribute the library declares, in declaration order" do
      component = Catalogue.fetch!(:map)
      %{attrs: declared} = MaplibreX.Components.Map.__components__().map

      assert {:ok, %{attrs: attrs}} = LibraryDocs.attributes(component)

      assert Enum.map(attrs, & &1.name) ==
               declared |> Enum.sort_by(& &1.line) |> Enum.map(& &1.name)
    end

    test "carries type, default and whether it is required" do
      {:ok, %{attrs: attrs}} = LibraryDocs.attributes(Catalogue.fetch!(:map))
      by_name = Map.new(attrs, &{&1.name, &1})

      assert %{type: "string", required: true, default: :none} = by_name.id
      assert %{type: "boolean", required: false, default: {:value, true}} = by_name.interactive
      assert %{type: "global"} = by_name.rest
    end

    test "uses the attr's own doc, then the function doc's bullet" do
      {:ok, %{attrs: attrs}} = LibraryDocs.attributes(Catalogue.fetch!(:map))
      by_name = Map.new(attrs, &{&1.name, &1})

      assert by_name.zoom.doc == "number"
      assert by_name.center.doc =~ "Map center coordinates"
    end

    test "lists allowed values" do
      {:ok, %{attrs: attrs}} = LibraryDocs.attributes(Catalogue.fetch!(:geolocate_control))
      position = Enum.find(attrs, &(&1.name == :position))

      assert "top-left" in position.values
    end

    test "lists slots" do
      {:ok, %{slots: slots}} = LibraryDocs.attributes(Catalogue.fetch!(:map))

      assert [%{name: :inner_block, required: false}] = slots
    end
  end

  describe "events/1" do
    test "reads the events from the component's documentation" do
      assert {:ok, events} = LibraryDocs.events(Catalogue.fetch!(:map))

      assert Enum.map(events, & &1.name) ==
               ~w(map:moved map:clicked map:loaded map:zoom_changed map:error)

      assert Enum.all?(events, &(&1.doc != ""))
    end

    test "falls back to the module documentation" do
      assert {:ok, events} = LibraryDocs.events(Catalogue.fetch!(:deckgl_layer))
      assert "deckgl:click" in Enum.map(events, & &1.name)
    end

    test "is empty for a component that sends none" do
      assert {:ok, []} = LibraryDocs.events(Catalogue.fetch!(:scale_control))
    end
  end

  test "version/0 is the version of the loaded library" do
    assert LibraryDocs.version() == to_string(Application.spec(:maplibrex, :vsn))
  end
end
