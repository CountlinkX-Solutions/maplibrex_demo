defmodule MaplibrexDemoWeb.DemoComponents do
  @moduledoc """
  The shared chrome every demo page is built from.

  Each demo used to carry its own copy of the back navigation, the glass
  control panel, the telemetry bar and the button styles. That made the pages
  drift apart. Everything visual now lives here, so a demo page contains only
  the map, its layers, and the controls specific to what it demonstrates.

  The design tokens live in `glass/0`, `ease/0` and `label_class/0` — they are
  functions rather than module attributes because inside `~H` a `@name` refers
  to an assign, not to a module attribute.
  """
  use Phoenix.Component
  use Gettext, backend: MaplibrexDemoWeb.Gettext

  use Phoenix.VerifiedRoutes,
    endpoint: MaplibrexDemoWeb.Endpoint,
    router: MaplibrexDemoWeb.Router,
    statics: MaplibrexDemoWeb.static_paths()

  @doc "Translucent dark surface shared by every floating panel."
  def glass, do: "bg-[rgba(8,12,28,0.82)] backdrop-blur-xl border border-white/[0.09]"

  @doc "The single easing curve used across the demo."
  def ease, do: "transition-all duration-300 ease-[cubic-bezier(0.32,0.72,0,1)]"

  @doc "Small uppercase section label."
  def label_class, do: "text-[9px] font-semibold uppercase tracking-[0.15em] text-white/35"

  @doc """
  The full-screen shell shared by every demo page.

  Renders the map layer, the back/locale navigation, the right-hand control
  panel and the bottom telemetry bar in consistent positions.

  ## Example

      <.demo_page path={~p"/map"} locale={@locale}
                  title={gettext("Interactive Map")}
                  subtitle={gettext("Markers, GeoJSON layers, real-time events")}>
        <:map>
          <.map id="demo-map" center={@center} zoom={@zoom} class="absolute inset-0 h-full w-full" />
        </:map>

        <:panel>
          <.panel_section label={gettext("Navigation")}>...</.panel_section>
        </:panel>

        <:telemetry>
          <.stat first label={gettext("Zoom")} value={@zoom} />
        </:telemetry>
      </.demo_page>
  """
  attr :path, :string,
    required: true,
    doc: "current path, used to return here after a locale switch"

  attr :locale, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil

  slot :map,
    required: true,
    doc: "the map component together with its controls, layers and sources"

  slot :panel, doc: "control panel contents; omit for a demo with no controls"
  slot :telemetry, doc: "the bottom-left readout; omit to hide the bar"

  def demo_page(assigns) do
    ~H"""
    <div class="relative h-screen w-full overflow-hidden bg-[#050810]">
      {render_slot(@map)}

      <.demo_nav path={@path} locale={@locale} />

      <div :if={@panel != []} class="absolute top-4 right-4 bottom-16 z-20 w-72 overflow-y-auto">
        <div class={[glass(), "space-y-5 rounded-2xl p-5"]}>
          <div>
            <p class={[label_class(), "mb-1"]}>MaplibreX</p>
            <h2 class="text-base font-semibold text-white">{@title}</h2>
            <p :if={@subtitle} class="mt-1 text-xs text-white/50">{@subtitle}</p>
          </div>

          {render_slot(@panel)}
        </div>
      </div>

      <div :if={@telemetry != []} class="absolute bottom-4 left-4 z-20">
        <div class={[glass(), "flex items-center gap-4 rounded-xl px-4 py-3"]}>
          {render_slot(@telemetry)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Back-to-demos pill and the EN/ES switcher.

  Sits below the map's own navigation control, which owns the top-left corner.
  """
  attr :path, :string, required: true
  attr :locale, :string, required: true

  def demo_nav(assigns) do
    ~H"""
    <div class="absolute top-[110px] left-4 z-20 flex flex-col gap-2">
      <a
        href={~p"/"}
        class={[
          glass(),
          ease(),
          "flex items-center gap-2 rounded-full px-4 py-2 text-sm text-white/75 no-underline hover:text-white"
        ]}
      >
        {gettext("Back to Demos")}
      </a>

      <div class={[glass(), "flex items-center gap-1 rounded-full px-3 py-1.5"]}>
        <.locale_link locale="en" current={@locale} path={@path} />
        <span class="text-[10px] text-white/20">|</span>
        <.locale_link locale="es" current={@locale} path={@path} />
      </div>
    </div>
    """
  end

  attr :locale, :string, required: true
  attr :current, :string, required: true
  attr :path, :string, required: true

  defp locale_link(assigns) do
    ~H"""
    <a
      href={~p"/locale?#{[locale: @locale, return_to: @path]}"}
      class={
        if @current == @locale,
          do: "text-[10px] font-semibold text-cyan-300 no-underline",
          else: "text-[10px] font-medium text-white/40 no-underline hover:text-white/70"
      }
    >
      {String.upcase(@locale)}
    </a>
    """
  end

  @doc """
  A single EN/ES link for pages outside the demo shell (the landing page).

  Unlike `demo_nav/1` this returns to the current path, which the landing page
  always knows is "/".
  """
  attr :locale, :string, required: true
  attr :current, :string, required: true
  attr :return_to, :string, default: "/"

  def locale_toggle(assigns) do
    ~H"""
    <a
      href={~p"/locale?#{[locale: @locale, return_to: @return_to]}"}
      class={
        if @current == @locale,
          do: "text-[0.65rem] font-bold text-cyan-400 no-underline",
          else: "text-[0.65rem] font-medium text-white/35 no-underline hover:text-white/60"
      }
    >
      {String.upcase(@locale)}
    </a>
    """
  end

  @doc """
  A labelled group inside the control panel, preceded by a divider.
  """
  attr :label, :string, required: true
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def panel_section(assigns) do
    ~H"""
    <div class="border-t border-white/[0.06]" />
    <div>
      <p class={[label_class(), "mb-2"]}>{@label}</p>
      <div class={@class}>{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc """
  A full-width option in a mutually exclusive list, e.g. picking a map style.
  """
  attr :active, :boolean, default: false
  attr :description, :string, default: nil
  attr :badge, :any, default: nil, doc: "trailing count, right-aligned"

  attr :rest, :global,
    include: ~w(phx-click phx-value-id phx-value-url phx-value-style phx-value-category)

  slot :inner_block, required: true

  def option_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "w-full rounded-lg px-3 py-2.5 text-left text-sm",
        ease(),
        if(@active,
          do: "border border-cyan-400/25 bg-cyan-500/10 text-cyan-300",
          else:
            "border border-transparent text-white/70 hover:border-white/[0.08] hover:bg-white/[0.07] hover:text-white"
        )
      ]}
      {@rest}
    >
      <span class="flex items-center justify-between font-medium">
        <span>{render_slot(@inner_block)}</span>
        <span :if={@badge} class="font-mono text-[11px] opacity-60">{@badge}</span>
      </span>
      <span :if={@description} class="mt-0.5 block text-xs text-white/40">{@description}</span>
    </button>
    """
  end

  @doc """
  A colour swatch paired with a label, for map legends.
  """
  attr :color, :string, required: true
  slot :inner_block, required: true

  def legend_item(assigns) do
    ~H"""
    <div class="flex items-center gap-2.5">
      <div class="h-2.5 w-2.5 shrink-0 rounded-full" style={"background-color: #{@color}"} />
      <span class="text-xs text-white/55">{render_slot(@inner_block)}</span>
    </div>
    """
  end

  @doc """
  A compact action button, sized to share a row with its siblings.
  """
  attr :rest, :global,
    include: ~w(phx-click phx-value-id phx-value-url phx-value-category phx-value-viz)

  slot :inner_block, required: true

  def action_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "flex-1 rounded-lg border border-white/[0.07] bg-white/[0.05] px-3 py-2 text-center text-xs text-white/70 hover:bg-white/[0.10]",
        ease()
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  A full-width on/off control that shows its own state.
  """
  attr :active, :boolean, required: true
  attr :on_label, :string, default: nil
  attr :off_label, :string, default: nil
  attr :rest, :global, include: ~w(phx-click phx-value-id)
  slot :inner_block, required: true

  def toggle_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "w-full rounded-lg px-3 py-2.5 text-left text-sm",
        ease(),
        if(@active,
          do: "border border-cyan-400/25 bg-cyan-500/10 text-cyan-300",
          else: "border border-white/[0.07] bg-white/[0.05] text-white/60"
        )
      ]}
      {@rest}
    >
      <span class="font-medium">{render_slot(@inner_block)}</span>
      <span :if={@on_label && @off_label} class="ml-2 text-xs opacity-70">
        {if @active, do: @on_label, else: @off_label}
      </span>
    </button>
    """
  end

  @doc """
  A labelled range input showing its current value.

  The input is wrapped in its own form so `phx-change` carries just this value.
  """
  attr :label, :string, required: true
  attr :name, :string, required: true
  attr :value, :any, required: true
  attr :min, :any, required: true
  attr :max, :any, required: true
  attr :step, :any, default: 1
  attr :on_change, :string, required: true, doc: "the phx-change event name"
  attr :display, :string, default: nil, doc: "formatted value; defaults to the raw value"

  def slider(assigns) do
    ~H"""
    <div>
      <div class="mb-1.5 flex items-baseline justify-between">
        <span class="text-xs text-white/60">{@label}</span>
        <span class="font-mono text-xs text-cyan-300">{@display || @value}</span>
      </div>
      <form phx-change={@on_change}>
        <input type="range" name={@name} value={@value} min={@min} max={@max} step={@step} />
      </form>
    </div>
    """
  end

  @doc """
  One reading in the bottom telemetry bar.

  Renders a leading divider unless `first` is set.
  """
  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :first, :boolean, default: false
  attr :class, :string, default: nil

  def stat(assigns) do
    ~H"""
    <div :if={!@first} class="h-6 w-px bg-white/10" />
    <div>
      <p class="text-[9px] tracking-widest text-white/35 uppercase">{@label}</p>
      <p class={["font-mono text-xs text-cyan-300", @class]}>{@value}</p>
    </div>
    """
  end

  @doc """
  A small read-only tag, used for listing layer or source names.
  """
  slot :inner_block, required: true

  def chip(assigns) do
    ~H"""
    <span class="inline-flex rounded border border-white/[0.07] bg-white/[0.05] px-2 py-1 text-[10px] text-white/60">
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  A colour ramp with low/high captions, for continuous-scale legends.
  """
  attr :css_gradient, :string, required: true
  attr :low, :string, required: true
  attr :high, :string, required: true

  def gradient_bar(assigns) do
    ~H"""
    <div class="space-y-2">
      <div class="h-2 rounded-full" style={"background: #{@css_gradient}"} />
      <div class="flex justify-between text-[9px] text-white/25">
        <span>{@low}</span>
        <span>{@high}</span>
      </div>
    </div>
    """
  end

  @doc """
  Min/max captions under a slider.
  """
  attr :min, :string, required: true
  attr :max, :string, required: true

  def slider_bounds(assigns) do
    ~H"""
    <div class="mt-1 flex justify-between text-[10px] text-white/25">
      <span>{@min}</span>
      <span>{@max}</span>
    </div>
    """
  end

  @doc """
  A row linking out to an external resource.
  """
  attr :href, :string, required: true
  slot :inner_block, required: true

  def link_row(assigns) do
    ~H"""
    <a
      href={@href}
      target="_blank"
      rel="noopener noreferrer"
      class={[
        "flex w-full items-center justify-between rounded-lg border border-white/[0.06] bg-white/[0.03] px-3 py-2 text-xs text-white/60 hover:bg-white/[0.07] hover:text-white",
        ease()
      ]}
    >
      <span>{render_slot(@inner_block)}</span>
      <span class="text-white/30">→</span>
    </a>
    """
  end

  @doc """
  Reachability of an external service the demo depends on.

  `/tiles` and `/ogc` both talk to a separate tile server. When it is not
  running, this says so instead of leaving a blank map with no explanation.
  """
  attr :status, :atom, required: true, doc: ":ok, :unreachable or :checking"
  attr :url, :string, required: true
  attr :hint, :string, default: nil

  def service_status(assigns) do
    ~H"""
    <div class={[
      "rounded-lg border px-3 py-2.5 text-xs",
      case @status do
        :ok -> "border-emerald-400/25 bg-emerald-500/10 text-emerald-300"
        :unreachable -> "border-amber-400/25 bg-amber-500/10 text-amber-200"
        _ -> "border-white/[0.07] bg-white/[0.05] text-white/50"
      end
    ]}>
      <div class="flex items-center gap-2">
        <span class={[
          "h-1.5 w-1.5 shrink-0 rounded-full",
          case @status do
            :ok -> "bg-emerald-400"
            :unreachable -> "bg-amber-400"
            _ -> "animate-pulse bg-white/40"
          end
        ]} />
        <span class="font-medium">
          {case @status do
            :ok -> gettext("Server online")
            :unreachable -> gettext("Server unreachable")
            _ -> gettext("Checking server…")
          end}
        </span>
      </div>

      <p class="mt-1 font-mono text-[10px] break-all opacity-70">{@url}</p>

      <p :if={@status == :unreachable && @hint} class="mt-1.5 leading-relaxed opacity-80">
        {@hint}
      </p>
    </div>
    """
  end
end
