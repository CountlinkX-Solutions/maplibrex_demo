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
      maplibrex_dep(),
      {:req, "~> 0.4"}
    ]
  end

  # MaplibreX ships its hooks and stylesheet as an npm package so that
  # `import "maplibrex"` resolves the same way whether the Elixir dependency
  # came from GitHub (deps/maplibrex) or from a local checkout (MAPLIBREX_PATH,
  # where Mix creates no deps/ entry at all).
  defp npm_install(_args) do
    args =
      case System.get_env("MAPLIBREX_PATH") do
        # package.json already points at deps/maplibrex.
        nil ->
          ["install", "--prefix", "assets"]

        # Override the checkout without rewriting the committed package.json.
        path ->
          ["install", "--prefix", "assets", "--no-save", "maplibrex@file:" <> Path.expand(path)]
      end

    {_out, 0} = System.cmd("npm", args, into: IO.stream())
    :ok
  end

  # Point at a local checkout while developing the library and the demo side by
  # side; fall back to the published repository otherwise.
  #
  #     MAPLIBREX_PATH=../maplibrex mix deps.get
  #
  defp maplibrex_dep do
    case System.get_env("MAPLIBREX_PATH") do
      nil -> {:maplibrex, github: "CountlinkX-Solutions/maplibrex"}
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
      "assets.build": ["tailwind maplibrex_demo", "esbuild maplibrex_demo"],
      "assets.deploy": [
        "tailwind maplibrex_demo --minify",
        "esbuild maplibrex_demo --minify",
        "phx.digest"
      ],
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
