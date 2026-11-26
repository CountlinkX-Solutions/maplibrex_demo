defmodule MaplibrexDemoWeb.Examples.CircleLayerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.CircleLayerExample

  @layer ~s(#example-circle-layer[phx-hook="CircleLayerHook"])

  defp mount_example(conn) do
    {:ok, view, _html} = live_isolated(conn, CircleLayerExample, session: %{"locale" => "en"})
    view
  end

  defp layer(fragment), do: ~s(#{@layer}[data-config*='#{fragment}'])

  test "draws the demo tiles' country centroids as circles", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(
             view,
             ~s(#example-circle-countries[phx-hook="VectorTileSourceHook"][data-config*="demotiles.maplibre.org"])
           )

    assert has_element?(view, layer(~s("sourceId":"example-circle-countries")))
    assert has_element?(view, layer(~s("sourceLayer":"centroids")))
    assert has_element?(view, layer(~s("circle-radius":6)))
    assert has_element?(view, layer(~s("circle-color":"#7c5cd6")))
  end

  test "the colour buttons and the radius slider set the paint", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-circle-color-teal") |> render_click()
    view |> element("#example-circle-options") |> render_change(%{"radius" => "10"})

    assert has_element?(view, layer(~s("circle-color":"#0f8b8d")))
    assert has_element?(view, layer(~s("circle-radius":10)))
    assert has_element?(view, ~s(#example-circle-color-teal[aria-pressed="true"]))
    assert has_element?(view, "#assign-radius", "10")
  end

  test "an unknown colour is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "color", %{"color" => "#000000"})

    assert has_element?(view, "#assign-color", "#7c5cd6")
  end

  test "a clicked circle comes back with its country's name", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "layer:feature_clicked", %{
      "layer_id" => "example-circle-layer",
      "feature" => %{"properties" => %{"NAME" => "Kenya", "ABBREV" => "Ken."}}
    })

    assert has_element?(view, "#assign-selected", "Kenya")
  end

  test "source:error is shown over the map", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "source:error", %{
      "source_id" => "example-circle-countries",
      "error" => "404"
    })

    assert has_element?(view, ~s(#example-circle-map-error[role="alert"]), "404")
  end
end
