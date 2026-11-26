defmodule MaplibrexDemoWeb.CatalogueComponents do
  @moduledoc """
  The building blocks of the catalogue pages: status marks and badges, code
  blocks with a copy button, issue lists and inline code in prose.

  Statuses are always shown as a mark and a word, never by colour alone.
  """
  use Phoenix.Component
  use Gettext, backend: MaplibrexDemoWeb.Gettext

  import MaplibrexDemoWeb.CoreComponents, only: [icon: 1]

  alias MaplibrexDemoWeb.{Catalogue, Highlight}
  alias Phoenix.LiveView.JS

  @statuses [:stable, :limited, :planned, :coming]

  @doc "The word for a status, translated."
  @spec status_word(atom()) :: String.t()
  def status_word(:stable), do: gettext("Stable")
  def status_word(:limited), do: gettext("Limited")
  def status_word(:planned), do: gettext("Planned")
  def status_word(:coming), do: gettext("Coming")

  @doc """
  The mark of a status: a small drawn icon in the status colour.

  Decorative on its own; pair it with the word (see `status_badge/1`) or a
  screen-reader label.
  """
  attr :status, :atom, required: true, values: @statuses
  attr :class, :any, default: nil

  def status_mark(assigns) do
    ~H"""
    <span data-status-mark={@status} aria-hidden="true" class={["inline-flex shrink-0", @class]}>
      <.icon :if={@status == :stable} name="hero-check-circle-micro" class="size-4 text-stable" />
      <.icon
        :if={@status == :limited}
        name="hero-exclamation-triangle-micro"
        class="size-4 text-limited"
      />
      <.icon :if={@status in [:planned, :coming]} name="hero-clock-micro" class="size-4 text-planned" />
    </span>
    """
  end

  @doc "A status as mark plus word on its tint."
  attr :status, :atom, required: true, values: @statuses
  attr :id, :string, default: nil
  attr :class, :string, default: nil

  def status_badge(assigns) do
    ~H"""
    <span
      id={@id}
      data-status={@status}
      class={[
        "inline-flex items-center gap-1 rounded-ui py-0.5 pr-2 pl-1.5 text-label font-bold whitespace-nowrap",
        badge_tint(@status),
        @class
      ]}
    >
      <.status_mark status={@status} />
      {status_word(@status)}
    </span>
    """
  end

  defp badge_tint(:stable), do: "bg-stable-soft text-stable"
  defp badge_tint(:limited), do: "bg-limited-soft text-limited"
  defp badge_tint(status) when status in [:planned, :coming], do: "bg-planned-soft text-planned"

  @doc """
  Prose that may name code between backticks, as the catalogue's notes do:
  "Changing `position` after mount has no effect."
  """
  attr :text, :string, required: true

  def rich_text(assigns) do
    ~H"{Phoenix.HTML.raw(rich_text_html(@text))}"
  end

  @doc false
  def rich_text_html(text) do
    text
    |> String.split("`")
    |> Enum.with_index()
    |> Enum.map(fn
      {part, index} when rem(index, 2) == 1 ->
        [~s(<code class="inline-code">), escape(part), "</code>"]

      {part, _index} ->
        escape(part)
    end)
    |> IO.iodata_to_binary()
  end

  defp escape(text), do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  @doc """
  The library issues behind a status, each with its note and a link.
  """
  attr :issues, :list, required: true
  attr :class, :string, default: nil

  def issue_list(assigns) do
    ~H"""
    <ul class={["space-y-1.5", @class]}>
      <li :for={issue <- @issues} class="text-ink-muted">
        <.rich_text text={issue.note} />
        <.issue_link number={issue.number} />
      </li>
    </ul>
    """
  end

  @doc "A link to one library issue on GitHub."
  attr :number, :integer, required: true

  def issue_link(assigns) do
    ~H"""
    <a
      href={Catalogue.issue_url(@number)}
      target="_blank"
      rel="noopener noreferrer"
      class="inline-flex items-center gap-0.5 font-mono text-label font-semibold whitespace-nowrap text-accent-ink underline-offset-2 hover:underline"
      aria-label={gettext("Library issue %{number} (opens GitHub)", number: @number)}
    >
      #{@number}<.icon name="hero-arrow-up-right-micro" class="size-3.5" />
    </a>
    """
  end

  @doc """
  A code block on the dark code ground, with a copy button.

  `code` is shown exactly as given, highlighted on the server (no CDN), and
  is what the copy button copies. `title` names the file or the step it
  belongs to.
  """
  attr :id, :string, required: true
  attr :code, :string, required: true

  attr :language, :atom,
    default: :plain,
    values: [:elixir, :heex, :javascript, :css, :shell, :plain]

  attr :title, :string, default: nil
  attr :class, :string, default: nil
  attr :max_height, :string, default: nil, doc: "a Tailwind max-height class for long sources"

  attr :html, :string,
    default: nil,
    doc: "the code already highlighted by `MaplibrexDemoWeb.Highlight.to_html/2`"

  def code_block(assigns) do
    assigns =
      assign_new(assigns, :highlighted, fn ->
        assigns.html || Highlight.to_html(assigns.code, assigns.language)
      end)

    ~H"""
    <figure
      id={@id}
      class={["overflow-hidden rounded-panel border border-code-line bg-code text-code-ink", @class]}
    >
      <figcaption class="flex h-10 items-center justify-between gap-3 border-b border-code-line pr-1.5 pl-4">
        <span class="truncate font-mono text-label text-code-muted">{@title ||
          language_label(@language)}</span>
        <.copy_button target={"#{@id}-code"} />
      </figcaption>
      <pre
        class={[
          "overflow-x-auto px-4 py-3.5 font-mono text-source",
          @max_height && "overflow-y-auto",
          @max_height
        ]}
        tabindex="0"
        phx-no-format
      ><code id={"#{@id}-code"}>{Phoenix.HTML.raw(@highlighted)}</code></pre>
    </figure>
    """
  end

  defp language_label(:elixir), do: "Elixir"
  defp language_label(:heex), do: "HEEx"
  defp language_label(:javascript), do: "JavaScript"
  defp language_label(:css), do: "CSS"
  defp language_label(:shell), do: "Shell"
  defp language_label(:plain), do: ""

  @doc """
  Copies the text of the element with id `target` to the clipboard.

  Runs entirely in the browser (see `assets/js/app.js`); the label switches
  to "Copied" for two seconds and is announced to screen readers.
  """
  attr :target, :string, required: true

  def copy_button(assigns) do
    ~H"""
    <button
      type="button"
      class="group inline-flex h-7 cursor-pointer items-center gap-1.5 rounded-ui px-2 text-label font-bold text-code-muted hover:bg-white/8 hover:text-code-ink"
      data-copy-target={@target}
      phx-click={JS.dispatch("app:copy")}
    >
      <.icon name="hero-clipboard-document-micro" class="size-3.5 group-data-copied:hidden" />
      <.icon name="hero-check-micro" class="hidden size-3.5 group-data-copied:inline-block" />
      <span aria-live="polite">
        <span class="group-data-copied:hidden">{gettext("Copy")}</span>
        <span class="hidden group-data-copied:inline">{gettext("Copied")}</span>
      </span>
    </button>
    """
  end
end
