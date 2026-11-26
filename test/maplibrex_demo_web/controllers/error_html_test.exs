defmodule MaplibrexDemoWeb.ErrorHTMLTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  alias MaplibrexDemoWeb.ErrorHTML

  defp document(html), do: LazyHTML.from_document(html)

  defp text(html, selector) do
    html |> document() |> LazyHTML.query(selector) |> LazyHTML.text() |> String.trim()
  end

  defp hrefs(html, selector) do
    html |> document() |> LazyHTML.query(selector) |> LazyHTML.attribute("href")
  end

  describe "404" do
    test "is a page of the demo that names the missing path and leads back" do
      conn = build_conn(:get, "/no/such/page")
      html = render_to_string(ErrorHTML, "404", "html", conn: conn)

      assert text(html, "title") == "Page not found · MaplibreX"
      assert hrefs(html, ~s(link[rel="stylesheet"])) == ["/assets/css/app.css"]
      assert text(html, "h1") == "Page not found"

      assert html
             |> document()
             |> LazyHTML.query("#error-message code")
             |> Enum.map(&LazyHTML.text/1)
             |> hd() ==
               "/no/such/page"

      assert hrefs(html, "#error-actions a") == ["/components", "/"]
      assert hrefs(html, "header a") == ["/"]
    end

    test "is what an unknown address gets, in the visitor's theme", %{conn: conn} do
      html = conn |> put_req_cookie("theme", "dark") |> get("/no/such/page") |> html_response(404)

      assert text(html, "h1") == "Page not found"

      assert html |> document() |> LazyHTML.query("html") |> LazyHTML.attribute("data-theme") ==
               ["dark"]
    end

    test "is in the visitor's language for an unknown component", %{conn: conn} do
      {404, _headers, html} =
        assert_error_sent 404, fn ->
          conn |> init_test_session(%{"locale" => "es"}) |> get("/components/no_such_component")
        end

      assert html |> document() |> LazyHTML.query("html") |> LazyHTML.attribute("lang") == ["es"]
      assert text(html, "h1") == "Página no encontrada"
    end
  end

  describe "500" do
    test "is a standalone page that says what failed and leads back" do
      html = render_to_string(ErrorHTML, "500", "html", conn: build_conn(:get, "/components"))

      assert text(html, "title") == "Server error · MaplibreX"
      assert hrefs(html, ~s(link[rel="stylesheet"])) == ["/assets/css/app.css"]
      assert text(html, "h1") == "The server could not build this page"
      assert text(html, "#error-message") =~ "log"
      assert hrefs(html, "#error-actions a") == ["/"]
      assert html |> document() |> LazyHTML.query("script") |> Enum.to_list() == []
    end
  end

  test "keeps the plain status message for any other status" do
    assert render_to_string(ErrorHTML, "503", "html", []) == "Service Unavailable"
  end
end
