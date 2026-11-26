defmodule MaplibrexDemoWeb.LocaleControllerTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "stores the locale and returns to the page it came from", %{conn: conn} do
    conn = get(conn, ~p"/locale?#{[locale: "es", return_to: "/components/map"]}")

    assert redirected_to(conn) == "/components/map"
    assert get_session(conn, "locale") == "es"
  end

  test "renders the next page in the chosen language", %{conn: conn} do
    conn = get(conn, ~p"/locale?#{[locale: "es", return_to: "/roadmap"]}")

    html = conn |> recycle() |> get(~p"/roadmap") |> html_response(200)

    assert html |> LazyHTML.from_document() |> LazyHTML.query(~s(html[lang="es"])) |> Enum.count() ==
             1

    {:ok, view, _html} = conn |> recycle() |> live(~p"/roadmap")
    assert has_element?(view, ~s(#locale-es[aria-current="true"]))
  end

  test "translates the catalogue's own copy", %{conn: conn} do
    conn = get(conn, ~p"/locale?#{[locale: "es", return_to: "/components/circle_layer"]}")

    {:ok, view, _html} = conn |> recycle() |> live(~p"/components/circle_layer")

    assert has_element?(
             view,
             "#component-summary",
             "Dibuja los puntos de una fuente como círculos."
           )

    assert has_element?(view, ~s(#component-status[data-status="stable"]), "Estable")
    assert has_element?(view, "#tab-preview", "Vista previa")
    assert has_element?(view, "#sidebar-family-markers-label", "Marcadores y popups")
  end

  test "translates the scenarios and the examples' own copy", %{conn: conn} do
    conn = get(conn, ~p"/locale?#{[locale: "es", return_to: "/scenarios/heatmap"]}")

    {:ok, view, _html} = conn |> recycle() |> live(~p"/scenarios/heatmap")

    assert has_element?(view, "#scenario-title", "Mapa de calor de sismos simulados")
    assert has_element?(view, "#scenario-sample-data", "Datos de ejemplo")

    {:ok, example, _html} =
      live_isolated(build_conn(), MaplibrexDemoWeb.Examples.MarkerExample,
        session: %{"locale" => "es"}
      )

    assert has_element?(example, "#example-marker-add", "Añadir en el centro")
  end

  for target <- ["//example.com/x", "https://example.com/x", "components"] do
    test "refuses to return to #{target}", %{conn: conn} do
      conn = get(conn, ~p"/locale?#{[locale: "es", return_to: unquote(target)]}")

      assert redirected_to(conn) == "/"
    end
  end

  test "ignores a locale it does not support", %{conn: conn} do
    conn = get(conn, ~p"/locale?#{[locale: "fr", return_to: "/roadmap"]}")

    assert redirected_to(conn) == "/"
    assert get_session(conn, "locale") == nil
  end
end
