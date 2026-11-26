defmodule MaplibrexDemoWeb.CataloguePagesTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.{Catalogue, LibraryDocs, OverviewLive, RoadmapLive}

  defp render_note(component, assigns),
    do: component |> render_component(assigns) |> LazyHTML.from_fragment()

  defp count(document, selector), do: document |> LazyHTML.query(selector) |> Enum.count()
  defp text(document, selector), do: document |> LazyHTML.query(selector) |> LazyHTML.text()

  describe "overview" do
    test "shows how to install the library and the minimal template", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#install-hooks code", "MapHooks")
      assert has_element?(view, "#minimal-template code", "<.map")
    end

    test "installs the library from the main branch the demo runs", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(
               view,
               "#install-dependency code",
               ~s({:maplibrex, github: "CountlinkX-Solutions/maplibrex", branch: "main"})
             )

      refute has_element?(view, "#install-dependency code", "~>")
    end

    test "names the release on Hex and what it lacks", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      state = if Catalogue.unreleased?(LibraryDocs.version()), do: "unreleased", else: "released"
      note = ~s(#install-hex-release[data-state="#{state}"])

      assert has_element?(view, note, Catalogue.hex_release())
      assert has_element?(view, "#install-step-dependency #{note}")
    end

    test "says the Hex release lacks the roadmap's fixes while main is ahead of it" do
      note =
        render_note(&OverviewLive.hex_release_note/1, version: "0.2.0", hex: "0.1.1")

      assert count(note, ~s(#install-hex-release[data-state="unreleased"])) == 1
      assert text(note, "#install-hex-release") =~ "0.1.1"
      assert count(note, ~s(#install-hex-release a[href="/roadmap#next-release-heading"])) == 1
    end

    test "says main has nothing unreleased once Hex has caught up" do
      note =
        render_note(&OverviewLive.hex_release_note/1, version: "0.2.0", hex: "0.2.0")

      assert count(note, ~s(#install-hex-release[data-state="released"])) == 1
      assert text(note, "#install-hex-release") =~ "0.2.0"
      assert count(note, "#install-hex-release a") == 0
    end

    test "links to the whole installation in the library's README", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(
               view,
               ~s(#install a[href="https://github.com/CountlinkX-Solutions/maplibrex#installation"])
             )
    end

    test "adds the hooks to the ones the generated LiveSocket has", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      hooks = "#install-step-hooks #install-hooks code"
      assert has_element?(view, hooks, "hooks: {...colocatedHooks, ...MapHooks}")
      assert has_element?(view, hooks, "longPollFallbackMs: 2500")
    end

    test "adds assets/node_modules to NODE_PATH in the esbuild profile", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      esbuild = "#install-step-hooks #install-esbuild code"
      assert has_element?(view, esbuild, ~s|Path.expand("../assets/node_modules", __DIR__)|)
      assert has_element?(view, esbuild, "--external:@deck.gl/*")
    end

    test "serves the maplibre-gl 6 worker in a step of its own", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      copy = "#install-step-worker #install-worker-copy code"
      assert has_element?(view, copy, "maplibre-gl-worker.mjs")
      assert has_element?(view, copy, "maplibre-gl-shared.mjs")
      assert has_element?(view, "#install-step-worker #install-worker-url code", "setWorkerUrl")
    end

    test "ends both examples with a catch-all handle_event/3 clause", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      for selector <- ["#install-import code", "#minimal-template code"] do
        # The rendered code loses the spaces between highlighted tokens, so
        # compare it with every space removed.
        [_before | clauses] =
          view
          |> element(selector)
          |> render()
          |> LazyHTML.from_fragment()
          |> LazyHTML.text()
          |> String.replace(~r/\s/, "")
          |> String.split("defhandle_event(")

        assert clauses != [], "#{selector} has no handle_event/3 clause"

        assert String.starts_with?(
                 List.last(clauses),
                 "_event,_params,socket),do:{:noreply,socket}"
               ),
               "#{selector} does not end with the catch-all clause"
      end
    end

    test "cites none of the closed installation issues", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      for number <- [41, 42] do
        refute has_element?(view, ~s(#overview a[href$="/issues/#{number}"]))
      end
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

    test "repeats each family's status counts under its name for narrow screens", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      for family <- Catalogue.families(), {status, n} <- family.statuses do
        assert has_element?(
                 view,
                 ~s(#family-row-#{family.id} th #family-summary-#{family.id} [data-status-summary="#{status}"]),
                 Integer.to_string(n)
               )
      end

      for {status, n} <- Catalogue.status_counts() do
        assert has_element?(
                 view,
                 ~s(#family-row-total th #family-summary-total [data-status-summary="#{status}"]),
                 Integer.to_string(n)
               )
      end

      for status <- [:stable, :limited, :planned] do
        assert has_element?(view, ~s(#family-legend [data-status-mark="#{status}"]))
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
      {:ok, view, _html} = live(conn, ~p"/components/circle_layer")

      assert has_element?(view, "#component-title", "circle_layer")
      assert has_element?(view, ~s(#component-status[data-status="stable"]), "Stable")
      assert has_element?(view, ~s(#component-status [data-status-mark="stable"]))
      assert has_element?(view, "#component-summary", Catalogue.fetch!(:circle_layer).summary)
      refute has_element?(view, "#component-issues")
    end

    test "explains a limited status and links its issue", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/popup")

      assert has_element?(view, ~s(#component-status[data-status="limited"]))

      assert has_element?(
               view,
               ~s(#component-issues a[href="https://github.com/CountlinkX-Solutions/maplibrex/issues/22"])
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
    test "leads with the release on Hex and the version the demo runs", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/roadmap")

      version = LibraryDocs.version()
      state = if Catalogue.unreleased?(version), do: "unreleased", else: "released"
      lead = ~s(#roadmap-lead[data-state="#{state}"])

      assert has_element?(view, lead, Catalogue.hex_release())
      assert has_element?(view, lead, version)
    end

    test "names main's version and the Hex release while main is ahead of it" do
      lead = render_note(&RoadmapLive.lead/1, version: "0.2.0", hex: "0.1.1")

      assert count(lead, ~s(#roadmap-lead[data-state="unreleased"])) == 1
      assert text(lead, "#roadmap-lead") =~ "MaplibreX 0.2.0"
      assert text(lead, "#roadmap-lead") =~ "main branch"
      assert text(lead, "#roadmap-lead") =~ "release on Hex is 0.1.1"
    end

    test "says main has nothing unreleased once Hex has caught up" do
      lead = render_note(&RoadmapLive.lead/1, version: "0.2.0", hex: "0.2.0")

      assert count(lead, ~s(#roadmap-lead[data-state="released"])) == 1
      assert text(lead, "#roadmap-lead") =~ "MaplibreX 0.2.0, the latest release on Hex"
      assert text(lead, "#roadmap-lead") =~ "nothing unreleased"
    end

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

      assert has_element?(view, "#roadmap-family-layers #roadmap-item-geojson_layer")
      assert has_element?(view, "#roadmap-family-three_d #roadmap-item-sky")
      refute has_element?(view, "#roadmap-family-layers #roadmap-item-circle_layer")
    end

    test "shows what the merged, unpublished release fixes, with its issues", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/roadmap")

      assert has_element?(view, "#next-release-heading", "0.2.0")
      assert has_element?(view, ~s(#next-release-state[data-state="merged"]))

      for %{issues: issues} <- Catalogue.next_release().items, number <- issues do
        assert has_element?(view, ~s(#next-release a[href$="/issues/#{number}"]))
      end
    end
  end

  describe "on this page" do
    defp query(view, selector, attribute) do
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(selector)
      |> LazyHTML.attribute(attribute)
    end

    for path <- ["/", "/roadmap"] do
      test "#{path} links every section heading from its rail", %{conn: conn} do
        {:ok, view, _html} = live(conn, unquote(path))

        assert has_element?(view, ~s(nav#page-rail[aria-labelledby="page-rail-title"]))
        assert has_element?(view, "#page-rail-title")
        assert has_element?(view, ~s(#page-rail[phx-hook="PageRail"][phx-update="ignore"]))

        targets = for "#" <> id <- query(view, "#page-rail a", "href"), do: id
        assert targets != []

        for id <- targets do
          assert has_element?(view, "#main h2##{id}, #main h3##{id}"), "no heading ##{id}"
        end

        assert query(view, "#main h2[id]", "id") -- targets == []
      end
    end

    test "the roadmap's rail lists each family under its section", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/roadmap")

      for family <- Catalogue.families(), Enum.any?(family.components, &(&1.status != :stable)) do
        assert has_element?(view, ~s(#page-rail a[href="#roadmap-family-#{family.id}-heading"]))
      end
    end

    test "a component page has no rail", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/map")

      refute has_element?(view, "#page-rail")
    end
  end

  describe "scenarios" do
    test "links every scenario to its page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/scenarios")

      for scenario <- Catalogue.scenarios() do
        assert has_element?(
                 view,
                 ~s(#scenario-#{scenario.id} a[href="/scenarios/#{scenario.id}"])
               )
      end

      refute has_element?(view, ~s([data-status="coming"]))
    end

    test "labels generated data as sample data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/scenarios")

      assert has_element?(view, "#scenario-heatmap [data-sample-data]")
      refute has_element?(view, "#scenario-terrain_3d [data-sample-data]")
    end
  end
end
