defmodule MaplibrexDemoWeb.LibraryDocs do
  @moduledoc """
  What the demo reads from the MaplibreX library itself, at run time, so that
  it cannot drift from the version it runs against.

    * `version/0` — the loaded `:maplibrex` application's version.
    * `attributes/1` — a component's attrs and slots from the metadata
      `Phoenix.Component` records (`__components__/0`). An attr without its
      own `doc:` takes the description from the bullet list under
      "## Attributes" in the component's documentation.
    * `events/1` — the events listed under "## Events" in the component's
      function documentation, or in its module documentation when the
      function's has none.
  """

  alias MaplibrexDemoWeb.Catalogue.Component

  @type attribute :: %{
          name: atom(),
          type: String.t(),
          required: boolean(),
          default: :none | {:value, term()},
          values: [term()] | nil,
          doc: String.t() | nil
        }

  @type slot :: %{name: atom(), required: boolean(), doc: String.t() | nil}
  @type event :: %{name: String.t(), doc: String.t()}

  @doc "The version of the MaplibreX application the demo is running."
  @spec version() :: String.t()
  def version do
    case Application.spec(:maplibrex, :vsn) do
      nil -> "?"
      vsn -> List.to_string(vsn)
    end
  end

  @doc """
  The component's attributes in the order the library declares them, and its
  slots. `:error` when the module does not describe the component.
  """
  @spec attributes(Component.t()) :: {:ok, %{attrs: [attribute()], slots: [slot()]}} | :error
  def attributes(%Component{name: name, module: module}) do
    with {:module, _} <- Code.ensure_loaded(module),
         true <- function_exported?(module, :__components__, 0),
         %{attrs: attrs, slots: slots} <- Map.get(module.__components__(), name) do
      bullets = module |> function_doc(name) |> bullets("Attributes")

      attrs =
        attrs
        |> Enum.sort_by(& &1.line)
        |> Enum.map(fn attr ->
          %{
            name: attr.name,
            type: type_label(attr.type),
            required: attr.required,
            default: default(attr.opts),
            values: Keyword.get(attr.opts, :values),
            doc: attr.doc || Map.get(bullets, Atom.to_string(attr.name))
          }
        end)

      slots =
        slots
        |> Enum.sort_by(& &1.line)
        |> Enum.map(&%{name: &1.name, required: &1.required, doc: &1.doc})

      {:ok, %{attrs: attrs, slots: slots}}
    else
      _ -> :error
    end
  end

  @doc """
  The events the component sends to the LiveView, as its documentation lists
  them. `:error` when the documentation is not available in this build.
  """
  @spec events(Component.t()) :: {:ok, [event()]} | :error
  def events(%Component{name: name, module: module}) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, module_doc, _, _} = docs ->
        from_function = docs |> function_doc_in(name) |> event_bullets()
        from_module = module_doc |> doc_text() |> event_bullets()

        {:ok, if(from_function == [], do: from_module, else: from_function)}

      {:error, _reason} ->
        :error
    end
  end

  defp event_bullets(doc) do
    doc
    |> section("Events")
    |> parse_bullets()
    |> Enum.filter(fn {name, _doc} -> String.contains?(name, ":") end)
    |> Enum.map(fn {name, doc} -> %{name: name, doc: doc} end)
  end

  defp bullets(doc, title), do: doc |> section(title) |> parse_bullets() |> Map.new()

  defp function_doc(module, name) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, _} = docs -> function_doc_in(docs, name)
      {:error, _reason} -> ""
    end
  end

  defp function_doc_in({:docs_v1, _, _, _, _, _, entries}, name) do
    Enum.find_value(entries, "", fn
      {{:function, ^name, 1}, _, _, doc, _} -> doc_text(doc)
      _ -> nil
    end)
  end

  defp doc_text(%{"en" => text}), do: text
  defp doc_text(_none), do: ""

  # The text under a "## Title" heading, up to the next "## " heading.
  defp section(doc, title) do
    case Regex.run(~r/^##\s+#{title}\s*\n(.*?)(?=^##\s|\z)/ms, doc) do
      [_, body] -> body
      nil -> ""
    end
  end

  # "* `name` (required) - Text that may continue
  #    on indented lines" -> [{"name", "Text that may continue on indented lines"}]
  defp parse_bullets(text) do
    text
    |> String.split("\n")
    |> Enum.reduce([], fn line, acc ->
      cond do
        match = Regex.run(~r/^\s*[*-]\s+`([^`]+)`(?:\s*\([^)]*\))?\s*(?:-|–|:)\s*(.*)$/, line) ->
          [_, name, doc] = match
          [{name, String.trim(doc)} | acc]

        acc != [] and Regex.match?(~r/^\s{2,}\S/, line) and
            not Regex.match?(~r/^\s*[*-]\s/, line) ->
          [{name, doc} | rest] = acc
          [{name, doc <> " " <> String.trim(line)} | rest]

        true ->
          acc
      end
    end)
    |> Enum.reverse()
  end

  defp type_label(type) when is_atom(type) do
    case Atom.to_string(type) do
      "Elixir." <> _ -> inspect(type)
      name -> name
    end
  end

  defp type_label({:fun, arity}), do: "fun/#{arity}"
  defp type_label({:struct, module}), do: inspect(module)
  defp type_label(other), do: inspect(other)

  defp default(opts) do
    case Keyword.fetch(opts, :default) do
      {:ok, value} -> {:value, value}
      :error -> :none
    end
  end
end
