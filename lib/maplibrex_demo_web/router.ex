defmodule MaplibrexDemoWeb.Router do
  use MaplibrexDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MaplibrexDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MaplibrexDemoWeb.Plugs.SetLocale
    plug MaplibrexDemoWeb.Plugs.SetTheme
  end

  scope "/", MaplibrexDemoWeb do
    pipe_through :browser

    get "/locale", LocaleController, :set

    live_session :catalogue,
      on_mount: [{MaplibrexDemoWeb.LocaleHook, :set_locale}, MaplibrexDemoWeb.CatalogueNav] do
      live "/", OverviewLive
      live "/components", ComponentsLive
      live "/components/:name", ComponentLive
      live "/scenarios", ScenariosLive
      live "/scenarios/:id", ScenarioLive
      live "/roadmap", RoadmapLive
    end

    # The pages that predate the catalogue, kept as redirects so bookmarks
    # land where the same thing is shown now. /tiles and /ogc needed a
    # separate tile server and are gone; they lead to the component index.
    get "/map", RedirectController, :show, assigns: %{to: "/components/map"}
    get "/markers", RedirectController, :show, assigns: %{to: "/components/marker"}
    get "/terrain", RedirectController, :show, assigns: %{to: "/scenarios/terrain_3d"}
    get "/heatmap", RedirectController, :show, assigns: %{to: "/scenarios/heatmap"}
    get "/buildings", RedirectController, :show, assigns: %{to: "/scenarios/buildings"}
    get "/particles", RedirectController, :show, assigns: %{to: "/scenarios/particles"}
    get "/deckgl", RedirectController, :show, assigns: %{to: "/scenarios/deckgl"}
    get "/tiles", RedirectController, :show, assigns: %{to: "/components"}
    get "/ogc", RedirectController, :show, assigns: %{to: "/components"}
  end
end
