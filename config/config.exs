# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :maplibrex_demo,
  generators: [timestamp_type: :utc_datetime],
  # The /tiles and /ogc demos read from a separate tile server (the sibling
  # `tileserver` project), not from this application. Both pages degrade to a
  # public basemap and say so when it is not reachable.
  #
  # Override at runtime with TILE_SERVER_URL — see config/runtime.exs.
  tile_server_url: "http://localhost:4000",
  # Public style used when the tile server is unreachable.
  fallback_style_url: "https://demotiles.maplibre.org/style.json"

# Configures the endpoint
config :maplibrex_demo, MaplibrexDemoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MaplibrexDemoWeb.ErrorHTML, json: MaplibrexDemoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MaplibrexDemo.PubSub,
  live_view: [signing_salt: "Ldr0iyFk"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  maplibrex_demo: [
    # --splitting: deck.gl is imported dynamically by MaplibreX, so code
    # splitting keeps it out of the main bundle — only /deckgl pays for it.
    # Requires format=esm, so root.html.heex loads app.js as type="module".
    #
    # --preserve-symlinks: `maplibrex` is installed as a `file:` dependency,
    # which npm links rather than copies. Without this, esbuild resolves the
    # bundle's peer imports (maplibre-gl, @deck.gl/*) relative to the library's
    # real location instead of this application's node_modules, and they fail.
    args: ~w(
        js/app.js
        --bundle
        --format=esm
        --splitting
        --chunk-names=chunks/[name]-[hash]
        --target=es2022
        --outdir=../priv/static/assets/js
        --preserve-symlinks
        --external:/fonts/*
        --external:/images/*
        --alias:@=.
      ),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  maplibrex_demo: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
