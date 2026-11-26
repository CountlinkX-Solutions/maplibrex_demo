defmodule MaplibrexDemoWeb.ScenarioLiveTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MaplibrexDemoWeb.Catalogue

  defp rebuilt, do: for(%{module: module} = s <- Catalogue.scenarios(), module, do: s)

  test "runs every rebuilt scenario above its template and module", %{conn: conn} do
    for %{id: id, module: module} <- rebuilt() do
      {:ok, view, _html} = live(conn, ~p"/scenarios/#{id}")
      base = module |> Module.split() |> List.last() |> Macro.underscore()

      assert find_live_child(view, "scenario-#{id}-live"), "#{id} runs no scenario"
      assert has_element?(view, "#scenario-source-#{base}-html-heex-code", "<.map")

      assert has_element?(
               view,
               "#scenario-source-#{base}-ex-code",
               "defmodule #{inspect(module)}"
             )
    end
  end

  test "caps its long sources behind a control", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/scenarios/heatmap")

    for file <- ["heatmap_scenario-html-heex", "heatmap_scenario-ex"] do
      assert has_element?(view, "#scenario-source-#{file}[data-collapsible]")
      assert has_element?(view, ~s(#scenario-source-#{file}-toggle[aria-expanded="false"]))
    end
  end

  test "shows the title, summary and the components it uses", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/scenarios/terrain_3d")
    {:ok, scenario} = Catalogue.fetch_scenario("terrain_3d")

    assert has_element?(view, "#scenario-title", scenario.title)
    assert has_element?(view, "#scenario-summary", scenario.summary)

    for name <- scenario.components do
      assert has_element?(view, ~s(#scenario-components a[href="/components/#{name}"]), "#{name}")
    end
  end

  test "names the library issues a scenario depends on", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/scenarios/deckgl")

    assert has_element?(view, ~s(#scenario-notes a[href$="/issues/11"]))
    assert has_element?(view, "#scenario-sample-data")
  end

  test "marks the scenarios section as current", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/scenarios/terrain_3d")

    assert has_element?(view, ~s(#nav-scenarios[aria-current="page"]))
  end

  test "links the previous and next rebuilt scenarios", %{conn: conn} do
    ids = Enum.map(rebuilt(), & &1.id)

    for {id, index} <- Enum.with_index(ids) do
      {:ok, view, _html} = live(conn, ~p"/scenarios/#{id}")

      case Enum.at(ids, index - 1) do
        previous when index > 0 ->
          assert has_element?(view, ~s(#scenario-previous[href="/scenarios/#{previous}"]))

        _ ->
          refute has_element?(view, "#scenario-previous")
      end

      case Enum.at(ids, index + 1) do
        nil -> refute has_element?(view, "#scenario-next")
        next -> assert has_element?(view, ~s(#scenario-next[href="/scenarios/#{next}"]))
      end
    end
  end
end
