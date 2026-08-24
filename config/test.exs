import Config

# Point the tile-server demos at a port nothing listens on, so the degraded
# path is what the test suite exercises — deterministically, whatever happens
# to be running on the developer's machine.
config :maplibrex_demo, tile_server_url: "http://127.0.0.1:1"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :maplibrex_demo, MaplibrexDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "acWcReIVDFmIQ1LYNUeQCRhnVhfX3zWj+BDV5FUHTSal2Yt2nyAXzAWACsH5qQXy",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
