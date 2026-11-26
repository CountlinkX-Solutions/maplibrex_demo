defmodule MaplibrexDemoWeb.Examples.TerrainExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.TerrainExample

  @terrain "#terrain-example-terrain-map"

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, TerrainExample, session: %{"locale" => "en"})
    view
  end

  defp set_options(view, options) do
    view
    |> element("#example-terrain-options")
    |> render_change(
      Map.merge(%{"exaggeration" => "1.5", "pitch" => "70", "enabled" => "true"}, options)
    )
  end

  test "renders terrain over a DEM source, next to a pitched map", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-terrain-map[phx-hook="MapHook"][data-config*="\\"pitch\\":70"])
           )

    assert has_element?(view, ~s(#example-terrain-map[data-config*="\\"maxPitch\\":85"]))
    assert has_element?(view, ~s(#example-terrain-dem[phx-hook="RasterDEMSourceHook"]))

    assert has_element?(
             view,
             ~s(#{@terrain}[phx-hook="TerrainHook"][data-config*="\\"sourceId\\":\\"example-terrain-dem\\""])
           )

    assert has_element?(view, ~s(#{@terrain}[data-config*="\\"exaggeration\\":1.5"]))
  end

  test "the sliders set the terrain's exaggeration and the map's pitch", %{conn: conn} do
    view = mount_example(conn)

    set_options(view, %{"exaggeration" => "2.5", "pitch" => "75"})

    assert has_element?(view, ~s(#{@terrain}[data-config*="\\"exaggeration\\":2.5"]))
    assert has_element?(view, ~s(#example-terrain-map[data-config*="\\"pitch\\":75"]))
    assert has_element?(view, "#assign-exaggeration", "2.5")
    assert has_element?(view, "#assign-pitch", "75")
  end

  test "a whole-number exaggeration still reaches the terrain as a float", %{conn: conn} do
    view = mount_example(conn)

    set_options(view, %{"exaggeration" => "2"})

    assert has_element?(view, ~s(#{@terrain}[data-config*="\\"exaggeration\\":2.0"]))
  end

  test "the enabled checkbox removes and brings back the terrain with :if", %{conn: conn} do
    view = mount_example(conn)

    set_options(view, %{"enabled" => "false"})
    refute has_element?(view, @terrain)
    assert has_element?(view, "#example-terrain-dem")

    set_options(view, %{"enabled" => "true"})
    assert has_element?(view, @terrain)
  end

  test "terrain:enabled and terrain:disabled keep the status", %{conn: conn} do
    view = mount_example(conn)
    assert has_element?(view, "#assign-status", "waiting")

    render_hook(view, "terrain:enabled", %{
      "source_id" => "example-terrain-dem",
      "exaggeration" => 1.5
    })

    assert has_element?(view, "#assign-status", "enabled")

    render_hook(view, "terrain:disabled", %{})
    assert has_element?(view, "#assign-status", "disabled")
  end

  test "map:moved brings the pitch back into the assigns", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "map:moved", %{
      "center" => [11.4, 47.3],
      "zoom" => 12,
      "pitch" => 42.5,
      "bearing" => 0
    })

    assert has_element?(view, "#assign-pitch", "42.5")
  end

  test "terrain:error and map:error are shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "terrain:error", %{"error" => "WebGL unavailable"})

    assert has_element?(view, ~s(#example-terrain-map-error[role="alert"]), "WebGL unavailable")
    assert has_element?(view, "#assign-status", "error")
  end
end
