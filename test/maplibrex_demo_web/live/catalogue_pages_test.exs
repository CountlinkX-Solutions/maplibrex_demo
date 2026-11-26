defmodule MaplibrexDemoWeb.CataloguePagesTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Catalogue

  describe "overview" do
    test "shows how to install the library and the minimal template", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#install-dependency code", ~s({:maplibrex, "~> 0.1.0"}))
      assert has_element?(view, "#install-hooks code", "MapHooks")
      assert has_element?(view, "#minimal-template code", "<.map")
    end

    test "counts each family's components and statuses from the catalogue", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      for family <- Catalogue.families() do
        row = "#family-row-#{family.id}"

        assert has_element?(view, "#{row} [data-count]", Integer.to_string(family.count))

        for {status, n} <- family.statuses do
          assert has_element?(
                   view,
                   ~s(#{row} [data-status-count="#{status}"]),
                   Integer.to_string(n)
                 )
        end
      end
    end

    test "leads into components, scenarios and the roadmap", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, ~s(#overview a[href="/components"]))
      assert has_element?(view, ~s(#overview a[href="/scenarios"]))
      assert has_element?(view, ~s(#overview a[href="/roadmap"]))
    end
  end

  describe "components index" do
    test "lists every component under its family with its status", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components")

      for component <- Catalogue.components() do
        assert has_element?(
                 view,
                 ~s(#family-#{component.family} #component-row-#{component.name} [data-status="#{component.status}"])
               )
      end
    end
  end

  describe "component page header" do
    test "shows the name, the status as mark and word, and the summary", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/marker")

      assert has_element?(view, "#component-title", "marker")
      assert has_element?(view, ~s(#component-status[data-status="stable"]), "Stable")
      assert has_element?(view, ~s(#component-status [data-status-mark="stable"]))
      assert has_element?(view, "#component-summary", Catalogue.fetch!(:marker).summary)
      refute has_element?(view, "#component-issues")
    end

    test "explains a limited status and links its issue", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/circle_layer")

      assert has_element?(view, ~s(#component-status[data-status="limited"]))

      assert has_element?(
               view,
               ~s(#component-issues a[href="https://github.com/CountlinkX-Solutions/maplibrex/issues/3"])
             )
    end

    test "explains a planned status and links its issue", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/sky")

      assert has_element?(view, ~s(#component-status[data-status="planned"]))
      assert has_element?(view, ~s(#component-issues a[href$="/issues/14"]))
    end

    test "links the previous and next components", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/marker")

      assert has_element?(view, ~s(#component-previous[href="/components/map"]))
      assert has_element?(view, ~s(#component-next[href="/components/popup"]))
    end
  end

  describe "roadmap" do
    test "lists every limited and planned component and no stable one", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/roadmap")

      for component <- Catalogue.components() do
        selector = "#roadmap-item-#{component.name}"

        if component.status == :stable do
          refute has_element?(view, selector)
        else
          assert has_element?(view, ~s(#{selector} [data-status="#{component.status}"]))

          for %{number: number} <- component.issues do
            assert has_element?(view, ~s(#{selector} a[href$="/issues/#{number}"]))
          end
        end
      end
    end

    test "groups the items by family", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/roadmap")

      assert has_element?(view, "#roadmap-family-layers #roadmap-item-circle_layer")
      assert has_element?(view, "#roadmap-family-three_d #roadmap-item-sky")
      refute has_element?(view, "#roadmap-family-markers #roadmap-item-marker")
    end

    test "shows the library work in progress with its issues", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/roadmap")

      for %{issues: issues} <- Catalogue.next_release().items, number <- issues do
        assert has_element?(view, ~s(#next-release a[href$="/issues/#{number}"]))
      end
    end
  end

  describe "scenarios" do
    test "marks every scenario as coming and links the page that shows it today", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/scenarios")

      for scenario <- Catalogue.scenarios() do
        selector = "#scenario-#{scenario.id}"

        assert has_element?(view, ~s(#{selector} [data-status="coming"]))
        assert has_element?(view, ~s(#{selector} a[href="#{scenario.legacy_path}"]))
      end
    end

    test "labels generated data as sample data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/scenarios")

      assert has_element?(view, "#scenario-heatmap [data-sample-data]")
      refute has_element?(view, "#scenario-terrain_3d [data-sample-data]")
    end
  end
end
