defmodule MaplibrexDemo.DevConfigTest do
  # What the development server reloads and rebuilds on its own.
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)

  defp live_reload_patterns do
    @root
    |> Path.join("config/dev.exs")
    |> Config.Reader.read!(env: :dev)
    |> get_in([:maplibrex_demo, MaplibrexDemoWeb.Endpoint, :live_reload, :patterns])
  end

  describe "live reload" do
    test "reloads the page when a source file of the web layer changes" do
      patterns = live_reload_patterns()

      for path <- [
            "lib/maplibrex_demo_web/examples/popup_example.ex",
            "lib/maplibrex_demo_web/examples/popup_example.html.heex",
            "lib/maplibrex_demo_web/scenarios/heatmap_scenario.html.heex",
            "lib/maplibrex_demo_web/catalogue.ex",
            "lib/maplibrex_demo_web/catalogue/component.ex",
            "lib/maplibrex_demo_web/highlight.ex",
            "lib/maplibrex_demo_web/library_docs.ex",
            "lib/maplibrex_demo_web/live/overview_live.ex",
            "lib/maplibrex_demo_web/components/layouts/root.html.heex",
            "lib/maplibrex_demo_web/router.ex",
            "priv/gettext/es/LC_MESSAGES/default.po",
            "priv/static/assets/css/app.css"
          ] do
        absolute = Path.join(@root, path)
        assert Enum.any?(patterns, &Regex.match?(&1, absolute)), "#{path} does not reload"
      end
    end

    test "ignores uploads and files outside the web layer" do
      patterns = live_reload_patterns()

      for path <- ["priv/static/uploads/photo.png", "test/test_helper.exs", "mix.exs"] do
        absolute = Path.join(@root, path)
        refute Enum.any?(patterns, &Regex.match?(&1, absolute)), "#{path} reloads"
      end
    end
  end

  describe "Tailwind" do
    # Explicit sources make the watcher's scope the directories that hold
    # classes, whatever the working directory and .gitignore say.
    test "scans the web layer and the JavaScript for classes" do
      css = File.read!(Path.join(@root, "assets/css/app.css"))

      assert css =~ ~s|@import "tailwindcss" source(none);|
      assert css =~ ~s|@source "../../lib/maplibrex_demo_web";|
      assert css =~ ~s|@source "../js";|
    end
  end
end
