# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :maplibrex_demo, generators: [timestamp_type: :utc_datetime]

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
    # Where `import "maplibrex"` comes from. esbuild resolves a bare import
    # in this order: tsconfig.json "paths" (assets/tsconfig.json maps only
    # the Phoenix packages), then node_modules directories up from the
    # importing file, then NODE_PATH. So `maplibrex` resolves to
    # assets/node_modules/maplibrex, the npm link that mix.exs keeps pointing
    # at the checkout Mix compiles: MAPLIBREX_PATH when it is set,
    # deps/maplibrex otherwise. A deps/maplibrex left over from the other
    # mode is never read.
    #
    # --preserve-symlinks: esbuild keeps the link's path instead of the
    # library's real location, so the bundle's peer imports (maplibre-gl,
    # @deck.gl/*) resolve from this application's assets/node_modules and the
    # demo, not the library, decides their versions.
    #
    # NODE_PATH is a generated Phoenix application's: deps/ for the Phoenix
    # packages and Mix's build path for colocated hooks.
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
