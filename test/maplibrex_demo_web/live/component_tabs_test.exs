defmodule MaplibrexDemoWeb.ComponentTabsTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.{Catalogue, LibraryDocs}

  defp count(view, selector) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> Enum.count()
  end

  test "opens on the preview tab", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/components/marker")

    assert has_element?(view, ~s(#tab-preview[aria-current="page"]))
    assert has_element?(view, "#panel-preview:not([hidden])")
    refute has_element?(view, "#panel-attributes")
  end

  test "switches tabs with a patch and keeps the preview mounted", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/components/marker")

    view |> element("#tab-attributes") |> render_click()

    assert_patch(view, ~p"/components/marker?tab=attributes")
    assert has_element?(view, ~s(#tab-attributes[aria-current="page"]))
    assert has_element?(view, "#panel-attributes")
    assert has_element?(view, "#panel-preview[hidden]")
  end

  test "falls back to the preview for an unknown tab", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/components/marker?tab=nonsense")

    assert has_element?(view, ~s(#tab-preview[aria-current="page"]))
  end

  describe "attributes tab" do
    test "has one row per attribute the library declares", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/geolocate_control?tab=attributes")
      {:ok, %{attrs: attrs}} = LibraryDocs.attributes(Catalogue.fetch!(:geolocate_control))

      assert count(view, "#attributes-table tbody tr") == length(attrs)
      assert has_element?(view, "#attr-map_id [data-required]")
      refute has_element?(view, "#attr-position [data-required]")
      assert has_element?(view, "#attr-position [data-default]", ~s("top-right"))
    end

    test "lists the slots", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/map?tab=attributes")

      assert has_element?(view, "#slot-inner_block")
    end
  end

  describe "events tab" do
    test "lists the events the library documents", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/marker?tab=events")

      for name <- ~w(marker-clicked marker-drag_start marker-dragging marker-drag_end) do
        assert has_element?(view, "#event-#{name}")
      end
    end

    test "says when a component sends no events", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/scale_control?tab=events")

      assert has_element?(view, "#events-empty")
    end
  end

  describe "a component without an example" do
    test "says the example is coming in the preview", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/popup")

      assert has_element?(view, "#example-coming")
    end

    test "has no source in the HEEx tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/popup?tab=heex")

      assert has_element?(view, "#source-empty")
    end

    test "explains a planned component has no example until its issue is fixed", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/sky")

      assert has_element?(view, ~s(#example-coming[data-status="planned"]))
    end
  end
end
