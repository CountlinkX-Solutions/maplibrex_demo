defmodule MaplibrexDemo.LibraryCheckoutTest do
  # The demo compiles MaplibreX's Elixir code with Mix and bundles its hooks and
  # stylesheet with esbuild and Tailwind. These tests keep both sides on the
  # same checkout: MAPLIBREX_PATH when it is set, deps/maplibrex otherwise.
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  defp project, do: Mix.Project.get!()

  describe "mix.lock" do
    # The demo follows the library's main branch; `mix deps.update maplibrex`
    # (run without MAPLIBREX_PATH) moves it to main's latest commit.
    test "locks MaplibreX to a commit of its main branch" do
      assert {:git, "https://github.com/CountlinkX-Solutions/maplibrex.git", sha, opts} =
               maplibrex_lock()

      assert sha =~ ~r/\A[0-9a-f]{40}\z/
      assert opts[:branch] == "main"
    end

    # The overview's install steps follow the library README at this commit,
    # the first with the fixes for #41 and #42. When the lock moves on, check
    # those steps against the README and move this with it.
    test "locks MaplibreX at the commit the overview's install steps follow" do
      assert {:git, _url, "363b3967d84f3b9829e298b2bf7bd8230c591bdf", _opts} = maplibrex_lock()
    end
  end

  defp maplibrex_lock do
    # Read as Mix does: the lock quotes every key.
    {lock, _binding} =
      "../../mix.lock"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Code.string_to_quoted!(emit_warnings: false)
      |> Code.eval_quoted()

    lock[:maplibrex]
  end

  describe "precommit" do
    # `mix compile` ignores an unknown switch such as --warning-as-errors, so a
    # misspelt flag would let warnings through without a word.
    test "compiles with warnings as errors" do
      assert "compile --warnings-as-errors" in project().project()[:aliases][:precommit]
    end
  end

  describe "maplibrex_checkout/0" do
    test "is the checkout Mix compiles the :maplibrex dependency from" do
      assert project().maplibrex_checkout() == Mix.Project.deps_paths()[:maplibrex]
    end
  end

  describe "maplibrex_linked?/2" do
    test "is true when the link points at the checkout", %{tmp_dir: tmp} do
      checkout = Path.join(tmp, "maplibrex")
      File.mkdir_p!(checkout)
      link = Path.join(tmp, "node_modules/maplibrex")
      File.mkdir_p!(Path.dirname(link))
      File.ln_s!("../maplibrex", link)

      assert project().maplibrex_linked?(link, checkout)
    end

    test "is false when the link points at another checkout", %{tmp_dir: tmp} do
      File.mkdir_p!(Path.join(tmp, "deps/maplibrex"))
      checkout = Path.join(tmp, "maplibrex")
      File.mkdir_p!(checkout)
      link = Path.join(tmp, "node_modules/maplibrex")
      File.mkdir_p!(Path.dirname(link))
      File.ln_s!("../deps/maplibrex", link)

      refute project().maplibrex_linked?(link, checkout)
    end

    test "is false when there is no link", %{tmp_dir: tmp} do
      refute project().maplibrex_linked?(Path.join(tmp, "node_modules/maplibrex"), tmp)
    end
  end

  describe "assets/tsconfig.json" do
    # esbuild applies tsconfig "paths" before node_modules. A catch-all such as
    # "*": ["../deps/*"] sent `import "maplibrex"` to whatever deps/maplibrex
    # held, even with MAPLIBREX_PATH pointing elsewhere.
    test "maps only Phoenix's own packages to deps/" do
      paths =
        "../../assets/tsconfig.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> String.replace(~r{^\s*//.*$}m, "")
        |> Jason.decode!()
        |> get_in(["compilerOptions", "paths"])

      assert Map.keys(paths) |> Enum.sort() == ["phoenix", "phoenix_html", "phoenix_live_view"]
    end
  end
end
