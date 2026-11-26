defmodule MaplibrexDemoWeb.Examples.PlumbingTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Catalogue
  alias MaplibrexDemoWeb.Examples.{BackgroundLayerExample, RasterTileSourceExample}
  alias MaplibrexDemoWeb.Scenarios.{DeckglScenario, HeatmapScenario, ParticlesScenario}

  # The basemap of every example and scenario follows the page's light or
  # dark theme. These keep one style in both themes: two examples whose
  # blank style leaves the whole map to their own layers, and three
  # scenarios whose data is drawn for a dark ground.
  @one_style [
    BackgroundLayerExample,
    RasterTileSourceExample,
    DeckglScenario,
    HeatmapScenario,
    ParticlesScenario
  ]

  @openfreemap "https://tiles.openfreemap.org/styles/"
  @light_styles Enum.map(~w(liberty positron bright), &(@openfreemap <> &1))
  @dark_styles Enum.map(~w(dark fiord), &(@openfreemap <> &1))

  defp modules do
    examples = for %{example: module} <- Catalogue.components(), module, do: module
    examples ++ Enum.map(Catalogue.scenarios(), & &1.module)
  end

  defp mount(conn, module) do
    {:ok, view, _html} = live_isolated(conn, module, session: %{"locale" => "en"})
    view
  end

  # The style the example's map is drawn with, from its configuration.
  defp map_style(view) do
    [config] =
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(~s([phx-hook="MapHook"]))
      |> LazyHTML.attribute("data-config")

    Jason.decode!(config)["style"]
  end

  test "there is an example or scenario for every theme check" do
    assert length(modules()) == 32
    assert Enum.all?(@one_style, &(&1 in modules()))
  end

  test "every example draws a light basemap until the browser reports a theme", %{conn: conn} do
    for module <- modules() -- @one_style do
      assert map_style(mount(conn, module)) in @light_styles, inspect(module)
    end
  end

  test "every example starts with the dark basemap when the browser connects in the dark theme",
       %{conn: conn} do
    conn = put_connect_params(conn, %{"theme" => "dark"})

    for module <- modules() -- @one_style do
      assert map_style(mount(conn, module)) in @dark_styles, inspect(module)
    end
  end

  test "every example switches its basemap when the theme changes, and back", %{conn: conn} do
    for module <- modules() -- @one_style do
      view = mount(conn, module)
      light = map_style(view)

      render_hook(view, "theme", %{"theme" => "dark"})
      assert map_style(view) in @dark_styles, inspect(module)

      render_hook(view, "theme", %{"theme" => "light"})
      assert map_style(view) == light, inspect(module)
    end
  end

  test "the blank-style examples and the dark scenarios keep one style", %{conn: conn} do
    for module <- @one_style do
      view = mount(conn, module)
      style = map_style(view)

      render_hook(view, "theme", %{"theme" => "dark"})
      assert map_style(view) == style, inspect(module)

      dark = mount(put_connect_params(conn, %{"theme" => "dark"}), module)
      assert map_style(dark) == style, inspect(module)
    end
  end

  test "a theme it does not know changes nothing", %{conn: conn} do
    view = mount(conn, MaplibrexDemoWeb.Examples.MapExample)
    style = map_style(view)

    render_hook(view, "theme", %{"theme" => "sepia"})
    render_hook(view, "theme", %{})

    assert map_style(view) == style
  end

  test "every example carries the hook that reports the theme", %{conn: conn} do
    for module <- modules() do
      assert has_element?(mount(conn, module), ~s(#example-theme[phx-hook="ExampleTheme"])),
             inspect(module)
    end
  end

  # LiveViewTest gives a nested LiveView no connect params, so this runs the
  # example on its component page with the theme event instead; the browser
  # checks cover the connect params of a nested example.
  test "on a component page, the running example follows the theme", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/components/map")
    example = find_live_child(view, "example-map-live")

    assert map_style(example) in @light_styles

    render_hook(example, "theme", %{"theme" => "dark"})

    assert map_style(example) in @dark_styles
  end
end
