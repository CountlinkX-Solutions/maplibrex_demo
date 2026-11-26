defmodule MaplibrexDemoWeb.ComponentExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  # The component page of `map`, the one component with an example so far.

  defp example(view), do: find_live_child(view, "example-map-live")

  test "runs the example in the preview, above its template", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/components/map")

    assert example(view)
    assert has_element?(view, "#panel-preview #example-map")
    assert has_element?(view, "#preview-source-code", "<.map")
    refute has_element?(view, "#example-coming")
  end

  test "caps the long template under the preview behind a control", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/components/map")

    assert has_element?(view, "#preview-source[data-collapsible]")
    assert has_element?(view, ~s(#preview-source-toggle[aria-expanded="false"]))
  end

  test "shows the sources whole in the HEEx tab", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/components/map?tab=heex")

    assert has_element?(view, "#panel-heex #source-map_example-ex-code")
    refute has_element?(view, "#panel-heex [data-collapsible]")
  end

  test "keeps the example running while another tab is open", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/components/map")
    child = example(view)

    view |> element("#tab-heex") |> render_click()

    assert has_element?(view, "#panel-preview[hidden] #example-map")
    assert example(view).pid == child.pid
  end

  test "shows the example's template and module in the HEEx tab", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/components/map?tab=heex")

    assert has_element?(view, "#source-map_example-html-heex-code", "<.map")

    assert has_element?(
             view,
             "#source-map_example-ex-code",
             "defmodule MaplibrexDemoWeb.Examples.MapExample"
           )

    refute has_element?(view, "#source-empty")
  end

  test "every component with an example runs it above its template", %{conn: conn} do
    for %{name: name, example: example} <- MaplibrexDemoWeb.Catalogue.components(), example do
      {:ok, view, _html} = live(conn, ~p"/components/#{name}")

      assert find_live_child(view, "example-#{name}-live"), "#{name} runs no example"
      assert has_element?(view, "#preview-source-code")
      refute has_element?(view, "#example-coming")
    end
  end

  test "shows the last payload of each event the example received", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/components/map?tab=events")

    assert has_element?(view, "#payload-map-moved-waiting")
    refute has_element?(view, "#payload-map-moved")

    render_hook(example(view), "map:moved", %{
      "center" => [-3.7, 40.42],
      "zoom" => 9.5,
      "pitch" => 0,
      "bearing" => 0
    })

    assert has_element?(view, "#payload-map-moved-code", "9.5")
    refute has_element?(view, "#payload-map-moved-waiting")
    assert has_element?(view, "#payload-map-clicked-waiting")
  end
end
