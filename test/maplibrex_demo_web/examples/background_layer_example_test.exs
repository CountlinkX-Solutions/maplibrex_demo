defmodule MaplibrexDemoWeb.Examples.BackgroundLayerExampleTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Examples.BackgroundLayerExample

  @layer ~s(#example-background-layer[phx-hook="BackgroundLayerHook"])

  defp mount_example(conn) do
    {:ok, view, _html} =
      live_isolated(conn, BackgroundLayerExample, session: %{"locale" => "en"})

    view
  end

  defp layer(fragment), do: ~s(#{@layer}[data-config*='#{fragment}'])

  test "paints the sea behind the demo tiles' countries on a blank style", %{conn: conn} do
    view = mount_example(conn)

    assert has_element?(view, ~s(#example-background-map[data-config*='"layers":[]']))
    assert has_element?(view, layer(~s("background-color":"#b9d9eb")))
    # Added before the land, so it stays under it without a before_id,
    # which would log a warning until the land arrives.
    refute has_element?(view, layer("beforeId"))

    assert has_element?(
             view,
             ~s(#example-background-land[phx-hook="FillLayerHook"][data-config*='"sourceLayer":"countries"'])
           )
  end

  test "the colour buttons and the opacity slider set the paint", %{conn: conn} do
    view = mount_example(conn)

    view |> element("#example-background-color-ink") |> render_click()
    view |> element("#example-background-options") |> render_change(%{"opacity" => "0.5"})

    assert has_element?(view, layer(~s("background-color":"#1f2330")))
    assert has_element?(view, layer(~s("background-opacity":0.5)))
    assert has_element?(view, ~s(#example-background-color-ink[aria-pressed="true"]))
  end

  test "an unknown colour is ignored", %{conn: conn} do
    view = mount_example(conn)

    render_click(view, "color", %{"color" => "#000000"})

    assert has_element?(view, "#assign-color", "#b9d9eb")
  end
end
