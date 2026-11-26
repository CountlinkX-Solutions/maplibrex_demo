defmodule MaplibrexDemoWeb.CatalogueComponents do
  @moduledoc """
  The building blocks of the catalogue pages: status marks and badges, code
  blocks with a copy button, issue lists and inline code in prose.

  Statuses are always shown as a mark and a word, never by colour alone.
  """
  use Phoenix.Component
  use Gettext, backend: MaplibrexDemoWeb.Gettext
  use MaplibrexDemoWeb, :verified_routes

  import MaplibrexDemoWeb.CoreComponents, only: [icon: 1]

  alias MaplibrexDemoWeb.{Catalogue, Highlight}
  alias Phoenix.LiveView.JS

  @statuses [:stable, :limited, :planned]

  @doc "The word for a status, translated."
  @spec status_word(atom()) :: String.t()
  def status_word(:stable), do: gettext("Stable")
  def status_word(:limited), do: gettext("Limited")
  def status_word(:planned), do: gettext("Planned")

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
      <.icon :if={@status == :planned} name="hero-clock-micro" class="size-4 text-planned" />
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
  defp badge_tint(:planned), do: "bg-planned-soft text-planned"

  @doc """
  Says that a scenario draws data generated for the demo, not real
  measurements.
  """
  attr :id, :string, default: nil

  def sample_data_badge(assigns) do
    ~H"""
    <span
      id={@id}
      data-sample-data
      class="inline-flex items-center gap-1 rounded-ui border border-line-strong py-0.5 pr-2 pl-1.5 text-label font-bold whitespace-nowrap text-ink-muted"
    >
      <.icon name="hero-beaker-micro" class="size-3.5 text-ink-subtle" />
      {gettext("Sample data")}
    </span>
    """
  end

  @doc "The components a scenario uses, each linked to its page."
  attr :id, :string, default: nil
  attr :names, :list, required: true
  attr :class, :string, default: nil

  def component_chips(assigns) do
    ~H"""
    <div id={@id} class={["flex flex-wrap items-center gap-x-2 gap-y-1.5 text-ui", @class]}>
      <span class="text-ink-subtle">{gettext("Uses")}</span>
      <.link
        :for={name <- @names}
        navigate={~p"/components/#{name}"}
        class="rounded-inline bg-surface px-1.5 py-0.5 text-label font-bold text-ink hover:bg-surface-hover hover:text-accent-ink"
      >
        {name}
      </.link>
    </div>
    """
  end

  @doc """
  The previous and next page of a sequence, at the foot of a page. Each is
  `%{name: name, path: path}`, or `nil` at either end.
  """
  attr :id, :string, required: true, doc: "the prefix of the two links' ids"
  attr :label, :string, required: true, doc: "the name of the navigation landmark"
  attr :previous, :map, default: nil
  attr :next, :map, default: nil

  def pager(assigns) do
    ~H"""
    <nav aria-label={@label} class="mt-16 grid gap-3 border-t border-line pt-6 sm:grid-cols-2">
      <.link
        :if={@previous}
        id={"#{@id}-previous"}
        navigate={@previous.path}
        class="group rounded-panel border border-line px-4 py-3 hover:border-line-strong hover:bg-surface"
      >
        <span class="block text-label text-ink-subtle">{gettext("Previous")}</span>
        <span class="mt-0.5 flex items-center gap-1.5 font-bold group-hover:text-accent-ink">
          <.icon name="hero-arrow-left-micro" class="size-4" />{@previous.name}
        </span>
      </.link>
      <.link
        :if={@next}
        id={"#{@id}-next"}
        navigate={@next.path}
        class="group rounded-panel border border-line px-4 py-3 text-right hover:border-line-strong hover:bg-surface sm:col-start-2"
      >
        <span class="block text-label text-ink-subtle">{gettext("Next")}</span>
        <span class="mt-0.5 flex items-center justify-end gap-1.5 font-bold group-hover:text-accent-ink">
          {@next.name}<.icon name="hero-arrow-right-micro" class="size-4" />
        </span>
      </.link>
    </nav>
    """
  end

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

  # A collapsed source shows this many lines (the `20lh` of the collapsed
  # height below), and only a source longer than the threshold collapses, so
  # the control never hides just a line or two.
  @collapsed_lines 20
  @collapse_threshold @collapsed_lines + 4

  @doc """
  A code block on the dark code ground, with a copy button.

  `code` is shown exactly as given, highlighted on the server (no CDN), and
  is what the copy button copies. `title` names the file or the step it
  belongs to.

  With `collapse`, a source longer than #{@collapse_threshold} lines shows
  its first #{@collapsed_lines} under a fade, with a "Show full source" button.
  The button toggles in the browser only (`JS.toggle_attribute/2`, which
  LiveView keeps across patches); the whole source stays in the page, so
  copying and screen readers always get all of it.
  """
  attr :id, :string, required: true
  attr :code, :string, required: true

  attr :language, :atom,
    default: :plain,
    values: [:elixir, :heex, :javascript, :css, :shell, :plain]

  attr :title, :string, default: nil
  attr :class, :string, default: nil
  attr :collapse, :boolean, default: false, doc: "cap a long source until the reader expands it"

  attr :html, :string,
    default: nil,
    doc: "the code already highlighted by `MaplibrexDemoWeb.Highlight.to_html/2`"

  def code_block(assigns) do
    assigns =
      assigns
      |> assign_new(:highlighted, fn ->
        assigns.html || Highlight.to_html(assigns.code, assigns.language)
      end)
      |> assign(:collapsible, assigns.collapse and line_count(assigns.code) > @collapse_threshold)

    ~H"""
    <figure
      id={@id}
      data-collapsible={@collapsible}
      class={[
        "group/code overflow-hidden rounded-panel border border-code-line bg-code text-code-ink",
        @class
      ]}
    >
      <figcaption class="flex h-10 items-center justify-between gap-3 border-b border-code-line pr-1.5 pl-4">
        <span class="truncate font-mono text-label text-code-muted">{@title ||
          language_label(@language)}</span>
        <.copy_button target={"#{@id}-code"} />
      </figcaption>
      <div class="relative">
        <pre
          id={"#{@id}-source"}
          class={[
            "overflow-x-auto px-4 py-3.5 font-mono text-source",
            @collapsible &&
              "max-h-[calc(20lh+1.75rem)] overflow-y-hidden group-data-expanded/code:max-h-none"
          ]}
          tabindex="0"
          phx-no-format
        ><code id={"#{@id}-code"}>{Phoenix.HTML.raw(@highlighted)}</code></pre>
        <div
          :if={@collapsible}
          id={"#{@id}-fade"}
          aria-hidden="true"
          class="pointer-events-none absolute inset-x-0 bottom-0 h-20 bg-linear-to-b from-transparent to-code group-data-expanded/code:hidden"
        />
      </div>
      <button
        :if={@collapsible}
        id={"#{@id}-toggle"}
        type="button"
        aria-expanded="false"
        aria-controls={"#{@id}-source"}
        class="flex h-10 w-full cursor-pointer items-center justify-center gap-1.5 border-t border-code-line text-label font-bold text-code-muted hover:bg-code-hover hover:text-code-ink focus-visible:-outline-offset-2"
        phx-click={
          JS.dispatch("app:code-toggle")
          |> JS.toggle_attribute({"aria-expanded", "true", "false"})
          |> JS.toggle_attribute({"data-expanded", ""}, to: "##{@id}")
        }
      >
        <span class="group-data-expanded/code:hidden">{gettext("Show full source")}</span>
        <.icon name="hero-chevron-down-micro" class="size-4 group-data-expanded/code:hidden" />
        <span class="hidden group-data-expanded/code:inline">{gettext("Show less")}</span>
        <.icon
          name="hero-chevron-up-micro"
          class="hidden size-4 group-data-expanded/code:inline-block"
        />
      </button>
    </figure>
    """
  end

  defp line_count(code), do: code |> String.trim_trailing() |> String.split("\n") |> length()

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
      class="group inline-flex h-7 cursor-pointer items-center gap-1.5 rounded-ui px-2 text-label font-bold text-code-muted hover:bg-code-hover hover:text-code-ink"
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
