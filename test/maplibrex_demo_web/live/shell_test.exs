defmodule MaplibrexDemoWeb.ShellTest do
  use MaplibrexDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp count(view, selector) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> Enum.count()
  end

  describe "top bar" do
    test "shows the version of the library the demo runs", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components")
      version = :maplibrex |> Application.spec(:vsn) |> to_string()

      assert has_element?(view, "#library-version", "v" <> version)
    end

    test "marks the current section", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/roadmap")

      assert has_element?(view, ~s(#nav-roadmap[aria-current="page"]))
      refute has_element?(view, "#nav-components[aria-current]")
    end

    test "offers a three-way theme switch", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components")

      for choice <- ~w(system light dark) do
        assert has_element?(view, ~s(#theme-switch button[data-theme-choice="#{choice}"]))
      end
    end
  end

  describe "sidebar" do
    test "groups every component under its family", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components")

      assert count(view, "#sidebar li[data-component]") == 32
      assert count(view, "#sidebar-family-layers li[data-component]") == 10
    end

    test "marks the component being viewed", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/marker")

      assert has_element?(view, ~s(#sidebar-item-marker[aria-current="page"]))
      refute has_element?(view, "#sidebar-item-map[aria-current]")
    end

    test "marks only the components that are not stable", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components")

      assert has_element?(view, ~s(#sidebar-item-sky [data-status-mark="planned"]))
      assert has_element?(view, ~s(#sidebar-item-circle_layer [data-status-mark="limited"]))
      refute has_element?(view, "#sidebar-item-marker [data-status-mark]")
    end

    test "is repeated in the drawer used on narrow screens", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components")

      assert has_element?(view, "dialog#nav-drawer #drawer-item-map")
      assert has_element?(view, ~s(#nav-drawer-open[aria-controls="nav-drawer"]))
    end
  end

  describe "component filter" do
    test "narrows the sidebar to matching names", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components")

      view |> element("#component-filter") |> render_change(%{"q" => "circle"})

      assert has_element?(view, "#sidebar-item-circle_layer")
      refute has_element?(view, "#sidebar-item-map")
      refute has_element?(view, "#sidebar-family-map")
    end

    test "says so when nothing matches, and can be cleared", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components")

      view |> element("#component-filter") |> render_change(%{"q" => "zzz"})
      assert has_element?(view, "#sidebar-empty")

      view |> element("#sidebar-empty button") |> render_click()
      refute has_element?(view, "#sidebar-empty")
      assert has_element?(view, "#sidebar-item-map")
    end

    test "opens the first match on submit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components")

      assert {:error, {:live_redirect, %{to: "/components/terrain_control"}}} =
               view |> element("#component-filter") |> render_submit(%{"q" => "terrain c"})
    end
  end

  describe "locale switch" do
    test "returns to the current page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components/map")

      assert has_element?(
               view,
               ~s(#locale-es[href="/locale?locale=es&return_to=%2Fcomponents%2Fmap"])
             )

      assert has_element?(view, ~s(#locale-en[aria-current="true"]))
    end
  end

  describe "connection status" do
    test "has hidden notices for a lost connection", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/components")

      assert has_element?(view, "#flash-group #client-error[hidden]")
      assert has_element?(view, "#flash-group #server-error[hidden]")
    end
  end
end
