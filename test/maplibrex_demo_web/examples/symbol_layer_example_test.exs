defmodule MaplibrexDemoWeb.Examples.SymbolLayerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.SymbolLayerExample

  @layer ~s(#example-symbol-labels[phx-hook="SymbolLayerHook"])

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, SymbolLayerExample, session: %{"locale" => "en"})
    view
  end

  defp layer(fragment), do: ~s(#{@layer}[data-config*='#{fragment}'])

  test "labels OpenStreetMap's points of interest with their names", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-symbol-osm[phx-hook="VectorTileSourceHook"][data-config*="tiles.openfreemap.org/planet"])
           )

    assert has_element?(view, layer(~s("sourceLayer":"poi")))
    assert has_element?(view, layer(~s("text-field":["get","name"])))
    assert has_element?(view, layer(~s("text-size":13)))
    assert has_element?(view, layer(~s("Noto Sans Regular")))
  end

  test "the text field and size are layout, the colour is paint", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-symbol-field-class") |> render_click()
    view |> element("#example-symbol-color-teal") |> render_click()
    view |> element("#example-symbol-options") |> render_change(%{"size" => "18"})

    assert has_element?(view, layer(~s("text-field":["get","class"])))
    assert has_element?(view, layer(~s("text-size":18)))
    assert has_element?(view, layer(~s("text-color":"#0f8b8d")))
    assert has_element?(view, ~s(#example-symbol-field-class[aria-pressed="true"]))
    assert has_element?(view, "#assign-field", "class")
  end

  test "an unknown field is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "field", %{"field" => "secret"})

    assert has_element?(view, "#assign-field", "name")
  end

  test "a clicked label comes back with its name", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "layer:feature_clicked", %{
      "layer_id" => "example-symbol-labels",
      "feature" => %{"properties" => %{"name" => "Albertina", "class" => "museum"}}
    })

    assert has_element?(view, "#assign-selected", "Albertina")
  end
end
