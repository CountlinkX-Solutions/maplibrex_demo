defmodule MaplibrexDemoWeb.Examples.ExampleComponents do
  @moduledoc """
  The layout around an example's own controls, so that an example's template
  reads as MaplibreX components and LiveView bindings rather than styling.

  None of this is needed to use MaplibreX. In an application, put the map and
  its controls in your own markup.
  """
  use Phoenix.Component
  use Gettext, backend: MaplibrexDemoWeb.Gettext

  import MaplibrexDemoWeb.CoreComponents, only: [icon: 1, input: 1]

  @doc """
  The box the map fills, at the preview's height: give the map
  `class="h-full w-full"`. Says the map is loading until MapLibre paints over
  it, and shows a map error on top. When its parent is shown in full screen,
  it takes the room the controls leave (see `app.css`).
  """
  attr :error, :string, default: nil, doc: "the last map:error message, if any"
  attr :error_id, :string, required: true

  attr :hosts, :list,
    default: ["tiles.openfreemap.org"],
    doc: "the services the example loads its map data from, named in an error"

  slot :inner_block, required: true

  def example_frame(assigns) do
    ~H"""
    <div data-example-frame class="relative h-preview overflow-hidden bg-surface">
      <p
        class="absolute inset-0 flex items-center justify-center gap-2 text-ui text-ink-subtle"
        aria-hidden="true"
      >
        <.icon name="hero-map" class="size-5" />
        {gettext("Loading the map")}
      </p>
      {render_slot(@inner_block)}
      <div
        :if={@error}
        id={@error_id}
        role="alert"
        class="absolute inset-x-3 top-3 z-10 flex items-start gap-2.5 rounded-ui border border-danger/40 bg-canvas px-3 py-2.5 text-ui shadow-overlay"
      >
        <.icon name="hero-exclamation-circle-mini" class="mt-px size-5 shrink-0 text-danger" />
        <p>
          <span class="font-bold">{gettext("The map reported an error:")}</span>
          <span class="font-mono text-label">{@error}</span>
          <span class="block text-ink-muted">
            {gettext(
              "The preview loads its map data from %{hosts}, so it needs an internet connection.",
              hosts: Enum.join(@hosts, ", ")
            )}
          </span>
        </p>
      </div>
    </div>
    """
  end

  @doc "A labelled row of controls."
  attr :label, :string, required: true
  attr :id, :string, required: true
  slot :inner_block, required: true

  def example_group(assigns) do
    ~H"""
    <div role="group" aria-labelledby={"#{@id}-label"} class="min-w-0">
      <p id={"#{@id}-label"} class="mb-2 text-label font-bold text-ink-subtle">{@label}</p>
      <div class="flex flex-wrap items-center gap-1.5">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc """
  A small button. `code` sets its label in the code face, for function names
  and attribute values. `pressed` marks the current choice of a set, with
  `aria-pressed`.
  """
  attr :code, :boolean, default: false
  attr :pressed, :boolean, default: nil, doc: "true or false for one of a set of choices"
  attr :rest, :global, include: ~w(disabled)
  slot :inner_block, required: true

  def example_button(assigns) do
    ~H"""
    <button
      type="button"
      aria-pressed={if(is_boolean(@pressed), do: to_string(@pressed))}
      class={[
        "inline-flex h-8 cursor-pointer items-center gap-1.5 rounded-ui border px-2.5 text-ui active:bg-surface-hover disabled:cursor-not-allowed disabled:opacity-50",
        if(@pressed,
          do: "border-accent-ink bg-accent-soft text-accent-ink",
          else: "border-line-strong bg-canvas hover:border-ink-subtle hover:bg-surface"
        ),
        if(@code, do: "font-mono text-label", else: "font-bold")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  A short note under the controls: that the data is sample data, or what
  the example needs to run.
  """
  attr :id, :string, required: true
  attr :icon, :string, default: "hero-beaker-micro"
  slot :inner_block, required: true

  def example_note(assigns) do
    ~H"""
    <p id={@id} class="flex items-start gap-1.5 text-label text-ink-muted">
      <.icon name={@icon} class="mt-px size-3.5 shrink-0 text-ink-subtle" />
      <span>{render_slot(@inner_block)}</span>
    </p>
    """
  end

  @doc "A dot of colour, for buttons that set a colour."
  attr :color, :string, required: true

  def example_swatch(assigns) do
    ~H"""
    <span
      class="size-3 shrink-0 rounded-full ring-1 ring-ink/25"
      style={"background-color: #{@color}"}
      aria-hidden="true"
    />
    """
  end

  @doc """
  A slider bound to a form field, labelled with the assign it sets. Its
  value arrives as a string, e.g. `"14.5"`.
  """
  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :rest, :global, include: ~w(min max step)

  def example_range(assigns) do
    ~H"""
    <.input
      field={@field}
      type="range"
      label={@label}
      wrapper_class="min-w-0 font-mono text-label text-ink-subtle"
      class="mt-1 block w-full cursor-pointer accent-accent"
      {@rest}
    />
    """
  end

  @doc "A checkbox bound to a form field, labelled with the assign it sets."
  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true

  def example_checkbox(assigns) do
    ~H"""
    <.input
      field={@field}
      type="checkbox"
      label={@label}
      wrapper_class="font-mono text-label text-ink-muted"
    />
    """
  end

  @doc """
  The current value of some assigns, as `@name value`. A value that changes
  is briefly highlighted: its element's id carries the value, so a new value
  is a new element and its entrance animation runs once.
  """
  attr :values, :list, required: true, doc: "a keyword list of assign name and shown value"

  def example_readout(assigns) do
    ~H"""
    <dl class="grid grid-cols-2 gap-x-6 gap-y-2 border-t border-line px-4 py-3 sm:grid-cols-3 lg:grid-cols-5">
      <div :for={{name, value} <- @values} class="min-w-0">
        <dt class="font-mono text-label text-ink-subtle">@{name}</dt>
        <dd id={"assign-#{name}"} class="truncate font-mono text-label text-ink tabular-nums">
          <span
            id={"assign-#{name}-#{:erlang.phash2(value)}"}
            class="-mx-1 rounded-[3px] px-1 motion-safe:animate-[assign-changed_1.4s_var(--ease-out-expo)]"
          >
            {value}
          </span>
        </dd>
      </div>
    </dl>
    """
  end
end
