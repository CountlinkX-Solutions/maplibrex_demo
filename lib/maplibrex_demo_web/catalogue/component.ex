defmodule MaplibrexDemoWeb.Catalogue.Component do
  @moduledoc """
  One MaplibreX component as the demo presents it.

    * `name` — the function name the library gives it, e.g. `:circle_layer`.
    * `family` — the id of the family it is listed under.
    * `module` — the library module that defines it, which `MaplibreX.Components`
      delegates to. Its `__components__/0` metadata feeds the Attributes tab.
    * `summary` — one sentence, already translated to the current locale.
    * `status` — `:stable`, `:limited` or `:planned`.
    * `issues` — the library issues behind a non-stable status, each with a
      one-sentence note, most important first.
    * `example` — the LiveView that demonstrates it, or `nil` while none exists.
    * `example_note` — why a component that works has no example, already
      translated, when the reason is not its status; `nil` otherwise.
  """

  @enforce_keys [:name, :family, :module, :summary, :status]
  defstruct [
    :name,
    :family,
    :module,
    :summary,
    :status,
    issues: [],
    example: nil,
    example_note: nil
  ]

  @type status :: :stable | :limited | :planned
  @type issue :: %{number: pos_integer(), note: String.t()}

  @type t :: %__MODULE__{
          name: atom(),
          family: atom(),
          module: module(),
          summary: String.t(),
          status: status(),
          issues: [issue()],
          example: module() | nil,
          example_note: String.t() | nil
        }
end
