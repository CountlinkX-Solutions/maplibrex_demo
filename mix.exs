defmodule MaplibrexDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :maplibrex_demo,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MaplibrexDemo.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.2"},
      # Phoenix.LiveViewTest parses the DOM with lazy_html from LiveView 1.2 on.
      {:lazy_html, ">= 0.1.0", only: :test},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      maplibrex_dep()
    ]
  end

  # MaplibreX ships its hooks and stylesheet as an npm package. esbuild
  # (`import "maplibrex"`) and Tailwind (`@import "maplibrex/css"`) both find it
  # through one npm link, assets/node_modules/maplibrex, which must point at
  # the checkout Mix compiles: MAPLIBREX_PATH when it is set, deps/maplibrex
  # otherwise. `mix assets.setup` creates the link; `mix assets.build`,
  # `mix assets.deploy` and `mix phx.server` re-create it first whenever it
  # points at the other checkout, so switching MAPLIBREX_PATH on or off needs
  # no extra step.
  defp npm_install(_args) do
    args =
      case System.get_env("MAPLIBREX_PATH") do
        # package.json already points at deps/maplibrex.
        nil ->
          ["install", "--prefix", "assets", "--no-audit", "--no-fund"]

        # Override the checkout without rewriting the committed package.json.
        _path ->
          ["install", "--prefix", "assets", "--no-audit", "--no-fund", "--no-save"] ++
            ["maplibrex@file:" <> maplibrex_checkout()]
      end

    {_out, 0} = System.cmd("npm", args, into: IO.stream())
    :ok
  end

  defp link_maplibrex(args) do
    link = Path.expand("assets/node_modules/maplibrex", __DIR__)

    if maplibrex_linked?(link, maplibrex_checkout()) do
      :ok
    else
      Mix.shell().info("Linking assets/node_modules/maplibrex to #{maplibrex_checkout()}")
      npm_install(args)
    end
  end

  @doc false
  # The checkout of MaplibreX that both Mix and the asset build use.
  # MAPLIBREX_PATH is relative to this file, as a Mix path dependency is.
  def maplibrex_checkout do
    case System.get_env("MAPLIBREX_PATH") do
      nil -> Path.expand("deps/maplibrex", __DIR__)
      path -> Path.expand(path, __DIR__)
    end
  end

  @doc false
  # Whether `link` is a symlink to `checkout`. npm writes relative links.
  def maplibrex_linked?(link, checkout) do
    case File.read_link(link) do
      {:ok, target} -> Path.expand(target, Path.dirname(link)) == Path.expand(checkout)
      {:error, _} -> false
    end
  end

  # The demo follows the library's main branch, not a Hex release: its
  # catalogue documents what main does. mix.lock holds the commit; move it
  # with `mix deps.update maplibrex`, run without MAPLIBREX_PATH.
  #
  # Point at a local checkout while developing the library and the demo side by
  # side:
  #
  #     MAPLIBREX_PATH=../maplibrex mix deps.get
  #
  defp maplibrex_dep do
    case System.get_env("MAPLIBREX_PATH") do
      nil -> {:maplibrex, github: "CountlinkX-Solutions/maplibrex", branch: "main"}
      path -> {:maplibrex, path: path}
    end
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        &npm_install/1
      ],
      "assets.build": [&link_maplibrex/1, "tailwind maplibrex_demo", "esbuild maplibrex_demo"],
      "assets.deploy": [
        &link_maplibrex/1,
        "tailwind maplibrex_demo --minify",
        "esbuild maplibrex_demo --minify",
        "phx.digest"
      ],
      # The dev server's esbuild and Tailwind watchers read the same link.
      "phx.server": [&link_maplibrex/1, "phx.server"],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
