defmodule MaplibrexDemoWeb.Examples.SourcesTest do
  use ExUnit.Case, async: true

  alias MaplibrexDemoWeb.Examples.{MapExample, Sources}
  alias MaplibrexDemoWeb.Highlight

  @dir "lib/maplibrex_demo_web/examples"

  test "reads an example's template and module, template first" do
    assert [template, module] = Sources.files(MapExample)

    assert template.path == "#{@dir}/map_example.html.heex"
    assert template.language == :heex
    assert module.path == "#{@dir}/map_example.ex"
    assert module.language == :elixir
  end

  test "shows exactly the source that runs" do
    for file <- Sources.files(MapExample) do
      assert file.source == File.read!(file.path)
      assert file.html == Highlight.to_html(file.source, file.language)
    end

    [template, module] = Sources.files(MapExample)
    assert template.source =~ "<.map"
    assert module.source =~ "defmodule MaplibrexDemoWeb.Examples.MapExample"
  end

  test "has nothing for a module that is not an example" do
    assert Sources.files(MaplibrexDemoWeb.CatalogueNav) == []
  end
end
