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
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MaplibrexDemoWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/locale", LocaleController, :set
    live "/map", MapLive
    live "/tiles", TilesLive
    live "/ogc", OgcFeaturesLive
    live "/deckgl", DeckglLive
    live "/terrain", TerrainLive
    live "/heatmap", HeatmapLive
    live "/buildings", BuildingsLive
    live "/markers", MarkersLive
    live "/particles", ParticlesLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", MaplibrexDemoWeb do
  #   pipe_through :api
  # end
end
