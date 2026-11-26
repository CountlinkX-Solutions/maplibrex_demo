defmodule MaplibrexDemoWeb.Highlight do
  @moduledoc """
  A small syntax highlighter for the code the demo shows: Elixir and HEEx in
  full, JavaScript, CSS and shell lightly.

  It runs on the server (and at compile time for example sources), so the
  page needs no highlighting library and no CDN. It is a lexer, not a
  parser: it only has to colour the demo's own, well-formed sources, and it
  never drops a character — joining the token texts always gives back the
  source, which the tests check.

  Token classes map to `tok-*` CSS classes in `assets/css/app.css`.
  """

  @type class ::
          :comment
          | :string
          | :atom
          | :attribute
          | :module
          | :number
          | :keyword
          | :function
          | :tag
          | :attr_name
          | :punct
          | nil

  @type token :: {class(), String.t()}
  @type language :: :elixir | :heex | :javascript | :css | :shell | :plain

  @doc "Splits `source` into classified tokens; adjacent tokens of one class are merged."
  @spec tokens(String.t(), language()) :: [token()]
  def tokens(source, language) when is_binary(source) do
    source
    |> lex(language)
    |> merge()
  end

  @doc "The highlighted source as HTML: every token escaped, classified ones in a span."
  @spec to_html(String.t(), language()) :: String.t()
  def to_html(source, language) do
    source
    |> tokens(language)
    |> Enum.map(fn
      {nil, text} -> escape(text)
      {class, text} -> [~s(<span class="tok-), css_class(class), ~s(">), escape(text), "</span>"]
    end)
    |> IO.iodata_to_binary()
  end

  defp css_class(:attr_name), do: "attr-name"
  defp css_class(class), do: Atom.to_string(class)

  defp escape(text), do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  defp lex(source, :elixir), do: elixir(source, []) |> Enum.reverse()
  defp lex(source, :heex), do: heex(source, []) |> Enum.reverse()

  defp lex(source, language) when language in [:javascript, :css, :shell],
    do: generic(source, language, []) |> Enum.reverse()

  defp lex(source, :plain), do: [{nil, source}]

  defp merge(tokens) do
    tokens
    |> Enum.reject(fn {_class, text} -> text == "" end)
    |> Enum.chunk_by(&elem(&1, 0))
    |> Enum.map(fn [{class, _} | _] = run -> {class, Enum.map_join(run, &elem(&1, 1))} end)
  end

  # -- Elixir ---------------------------------------------------------------

  @elixir_keywords ~w(defmodule defmacrop defmacro defp def defstruct defdelegate defimpl defprotocol
                      defexception do end fn case cond if else unless when with for in use import
                      alias require quote unquote receive after try rescue catch raise and or not)

  defp elixir("", acc), do: acc

  defp elixir(source, acc) do
    cond do
      match = run(~r/\A~H("""|''')\n.*?\n[ \t]*\1/s, source) ->
        {open, rest_of_sigil} = String.split_at(match, 4)
        {content, close} = split_closing(rest_of_sigil)
        acc = heex(content, [{:string, open} | acc])
        elixir(drop(source, match), [{:string, close} | acc])

      true ->
        {class, text} = elixir_token(source)
        elixir(drop(source, text), [{class, text} | acc])
    end
  end

  # Splits a heredoc body from its closing line: "  body\n  \"\"\"" -> {"  body\n", "  \"\"\""}.
  defp split_closing(text) do
    [_, content, close] = Regex.run(~r/\A(.*\n)([ \t]*(?:"""|'''))\z/s, text)
    {content, close}
  end

  defp elixir_token(source) do
    rules = [
      {~r/\A\s+/, nil},
      {~r/\A#[^\n]*/, :comment},
      {~r/\A(?:~[a-zA-Z])?("""|''')\n.*?\n[ \t]*\1/s, :string},
      {~r/\A"(?:\\.|[^"\\])*"/s, :string},
      {~r/\A'(?:\\.|[^'\\])*'/s, :string},
      {~r/\A~[a-zA-Z](?:"(?:\\.|[^"\\])*"|\((?:\\.|[^)\\])*\)|\[(?:\\.|[^\]\\])*\]|\{(?:\\.|[^}\\])*\}|\/(?:\\.|[^\/\\])*\/|\|(?:\\.|[^|\\])*\||<(?:\\.|[^>\\])*>)[a-zA-Z]*/s,
       :string},
      {~r/\A::/, :punct},
      {~r/\A:(?:[a-zA-Z_][a-zA-Z0-9_@]*[?!]?|"(?:\\.|[^"\\])*")/, :atom},
      {~r/\A[a-zA-Z_][a-zA-Z0-9_]*[?!]?:(?=\s)/, :atom},
      {~r/\A@[a-zA-Z_][a-zA-Z0-9_]*/, :attribute},
      {~r/\A[A-Z][a-zA-Z0-9_]*(?:\.[A-Z][a-zA-Z0-9_]*)*/, :module},
      {~r/\A(?:0x[0-9a-fA-F_]+|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d+)?)/, :number},
      {~r/\A(?:true|false|nil)(?![a-zA-Z0-9_?!:])/, :atom},
      {~r/\A[a-z_][a-zA-Z0-9_]*[?!]?(?=\()/, :function},
      {~r/\A[a-z_][a-zA-Z0-9_]*[?!]?/, :identifier},
      {~r/\A(?:\|>|->|<-|=>|\\\\|&&|\|\||===|!==|==|!=|<=|>=|<>|\+\+|--|\.\.|[=+\-*\/<>!&|^%.,;()\[\]{}])/,
       :punct}
    ]

    case first_match(rules, source) do
      {:identifier, word} -> {if(word in @elixir_keywords, do: :keyword), word}
      {class, text} -> {class, text}
      nil -> {nil, first_grapheme(source)}
    end
  end

  # -- HEEx -----------------------------------------------------------------

  defp heex("", acc), do: acc

  defp heex(source, acc) do
    cond do
      match = run(~r/\A<%!--.*?--%>/s, source) ->
        heex(drop(source, match), [{:comment, match} | acc])

      match = run(~r/\A<!--.*?-->/s, source) ->
        heex(drop(source, match), [{:comment, match} | acc])

      match = run(~r/\A<%=?.*?%>/s, source) ->
        [_, open, code, close] = Regex.run(~r/\A(<%=?)(.*)(%>)\z/s, match)
        acc = [{:punct, close} | elixir(code, [{:punct, open} | acc])]
        heex(drop(source, match), acc)

      match = run(~r/\A<\/[.:]?[a-zA-Z][\w.:-]*\s*>/, source) ->
        heex(drop(source, match), [{:tag, match} | acc])

      match = run(~r/\A<[.:]?[a-zA-Z][\w.:-]*/, source) ->
        heex_tag(drop(source, match), [{:tag, match} | acc])

      String.starts_with?(source, "{") ->
        {acc, rest} = expression(source, acc)
        heex(rest, acc)

      match = run(~r/\A[^<{]+/, source) ->
        heex(drop(source, match), [{nil, match} | acc])

      true ->
        char = first_grapheme(source)
        heex(drop(source, char), [{nil, char} | acc])
    end
  end

  # Inside an opening tag, up to its ">" or "/>".
  defp heex_tag("", acc), do: acc

  defp heex_tag(source, acc) do
    cond do
      match = run(~r/\A\/?>/, source) ->
        heex(drop(source, match), [{:tag, match} | acc])

      match = run(~r/\A\s+/, source) ->
        heex_tag(drop(source, match), [{nil, match} | acc])

      match = run(~r/\A[:@a-zA-Z_][\w:.@-]*/, source) ->
        heex_tag(drop(source, match), [{:attr_name, match} | acc])

      match = run(~r/\A=/, source) ->
        heex_tag(drop(source, match), [{:punct, match} | acc])

      match = run(~r/\A(?:"[^"]*"|'[^']*')/, source) ->
        heex_tag(drop(source, match), [{:string, match} | acc])

      String.starts_with?(source, "{") ->
        {acc, rest} = expression(source, acc)
        heex_tag(rest, acc)

      true ->
        char = first_grapheme(source)
        heex_tag(drop(source, char), [{nil, char} | acc])
    end
  end

  # A `{...}` interpolation: its braces as punctuation, its body as Elixir.
  # An unbalanced brace is left as text.
  defp expression("{" <> rest = source, acc) do
    case take_braced(rest, 0, []) do
      {:ok, code, after_brace} ->
        acc = [{:punct, "}"} | elixir(code, [{:punct, "{"} | acc])]
        {acc, after_brace}

      :error ->
        {[{nil, source} | acc], ""}
    end
  end

  # Scans to the brace that closes the one already consumed, skipping strings.
  defp take_braced("", _depth, _code), do: :error
  defp take_braced("}" <> rest, 0, code), do: {:ok, IO.iodata_to_binary(Enum.reverse(code)), rest}
  defp take_braced("}" <> rest, depth, code), do: take_braced(rest, depth - 1, ["}" | code])
  defp take_braced("{" <> rest, depth, code), do: take_braced(rest, depth + 1, ["{" | code])

  defp take_braced("\"" <> _ = source, depth, code) do
    case run(~r/\A"(?:\\.|[^"\\])*"/s, source) do
      nil -> :error
      string -> take_braced(drop(source, string), depth, [string | code])
    end
  end

  defp take_braced(source, depth, code) do
    {char, rest} = String.split_at(source, 1)
    take_braced(rest, depth, [char | code])
  end

  # -- JavaScript, CSS, shell -------------------------------------------------

  @js_keywords ~w(import from export default let const var new function return if else for of async await)

  defp generic("", _language, acc), do: acc

  defp generic(source, language, acc) do
    comment =
      case language do
        :shell -> ~r/\A#[^\n]*/
        :css -> ~r/\A\/\*.*?\*\//s
        :javascript -> ~r/\A(?:\/\/[^\n]*|\/\*.*?\*\/)/s
      end

    rules = [
      {~r/\A\s+/, nil},
      {comment, :comment},
      {~r/\A(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)/s, :string},
      {~r/\A@[a-zA-Z-]+/, :keyword},
      {~r/\A\d[\d.]*/, :number},
      {~r/\A[a-zA-Z_$][\w$-]*(?=\()/, :function},
      {~r/\A[a-zA-Z_$][\w$-]*/, :identifier},
      {~r/\A[{}()\[\];:,.=<>+\-*\/!&|?]/, :punct}
    ]

    {class, text} =
      case first_match(rules, source) do
        {:identifier, word} ->
          {if(language == :javascript and word in @js_keywords, do: :keyword), word}

        {class, text} ->
          {class, text}

        nil ->
          {nil, first_grapheme(source)}
      end

    generic(drop(source, text), language, [{class, text} | acc])
  end

  # -- helpers ----------------------------------------------------------------

  defp first_match(rules, source) do
    Enum.find_value(rules, fn {regex, class} ->
      case run(regex, source) do
        nil -> nil
        "" -> nil
        text -> {class, text}
      end
    end)
  end

  defp run(regex, source) do
    case Regex.run(regex, source, capture: :first) do
      [match] -> match
      nil -> nil
    end
  end

  defp drop(source, prefix),
    do: binary_part(source, byte_size(prefix), byte_size(source) - byte_size(prefix))

  defp first_grapheme(source) do
    {char, _rest} = String.next_grapheme(source)
    char
  end
end
