defmodule MaplibrexDemoWeb.Examples.Sources do
  @moduledoc """
  The source files of every example and scenario, read and highlighted at
  compile time.

  An example `FooExample` lives in `foo_example.ex` with its template in
  `foo_example.html.heex`, in this directory; a scenario `FooScenario` the
  same way in `../scenarios`. Each file is an external resource of this
  module, so editing one recompiles it, and adding or removing one does too
  (`__mix_recompile__?/0`). What the pages show is therefore always the code
  that runs.
  """
  alias MaplibrexDemoWeb.Highlight

  @type file :: %{
          name: String.t(),
          path: String.t(),
          language: :heex | :elixir,
          source: String.t(),
          html: String.t()
        }

  @patterns [
    Path.join(__DIR__, "*_example.{html.heex,ex}"),
    Path.expand("../scenarios/*_scenario.{html.heex,ex}", __DIR__)
  ]
  @paths @patterns |> Enum.flat_map(&Path.wildcard/1) |> Enum.sort()
  @paths_hash :erlang.md5(@paths)

  for path <- @paths, do: @external_resource(path)

  @files (for path <- @paths do
            language = if String.ends_with?(path, ".heex"), do: :heex, else: :elixir
            source = File.read!(path)

            %{
              name: Path.basename(path),
              path: Path.relative_to_cwd(path),
              language: language,
              source: source,
              html: Highlight.to_html(source, language)
            }
          end)

  @doc false
  def __mix_recompile__? do
    @patterns |> Enum.flat_map(&Path.wildcard/1) |> Enum.sort() |> :erlang.md5() != @paths_hash
  end

  @doc """
  The files of an example or scenario module: its template first, then the
  module. Empty for any other module.
  """
  @spec files(module()) :: [file()]
  def files(module) when is_atom(module) do
    base = module |> Module.split() |> List.last() |> Macro.underscore()

    for name <- [base <> ".html.heex", base <> ".ex"],
        file = Enum.find(@files, &(&1.name == name)),
        do: file
  end
end
