defmodule MaplibrexDemoWeb.ScenariosLive do
  @moduledoc """
  Scenarios: several components combined into one working map.

  None has been rebuilt in the catalogue yet. Each is marked as coming and
  links the page that shows it today, so nothing that works is hidden.
  """
  use MaplibrexDemoWeb, :live_view

  alias MaplibrexDemoWeb.Catalogue

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, gettext("Scenarios"))}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :scenarios, Catalogue.scenarios())

    ~H"""
    <Layouts.app
      flash={@flash}
      locale={@locale}
      current_path={@current_path}
      query={@query}
      section={:scenarios}
    >
      <header class="max-w-measure">
        <h1 class="text-display font-black tracking-tight">{gettext("Scenarios")}</h1>
        <p class="mt-3 text-lead text-ink-muted">
          {gettext(
            "A scenario combines several components into one working map, with the code that produces it. These are being rebuilt in the catalogue; until then, each links to the page that shows it today."
          )}
        </p>
      </header>

      <ul class="mt-10 divide-y divide-line border-y border-line">
        <li :for={scenario <- @scenarios} id={"scenario-#{scenario.id}"} class="py-6">
          <article aria-labelledby={"scenario-#{scenario.id}-heading"}>
            <div class="flex flex-wrap items-center gap-x-3 gap-y-2">
              <h2 id={"scenario-#{scenario.id}-heading"} class="text-heading font-black">
                {scenario.title}
              </h2>
              <.status_badge status={scenario.status} />
              <span
                :if={scenario.sample_data}
                data-sample-data
                class="inline-flex items-center rounded-ui border border-line-strong px-2 py-0.5 text-label font-bold text-ink-muted"
              >
                {gettext("Sample data")}
              </span>
            </div>

            <p class="mt-2 max-w-measure text-body text-ink-muted">{scenario.summary}</p>

            <p :if={scenario.sample_data} class="mt-1 max-w-measure text-ui text-ink-subtle">
              {gettext("The page draws data generated for the demo, not real measurements.")}
            </p>

            <div class="mt-3 flex flex-wrap items-center gap-x-2 gap-y-1.5 text-ui">
              <span class="text-ink-subtle">{gettext("Uses")}</span>
              <.link
                :for={name <- scenario.components}
                navigate={~p"/components/#{name}"}
                class="rounded-[4px] bg-surface px-1.5 py-0.5 font-mono text-label text-ink hover:bg-surface-hover hover:text-accent-ink"
              >
                {name}
              </.link>
            </div>

            <a
              href={scenario.legacy_path}
              class="mt-4 inline-flex items-center gap-1.5 text-ui font-bold text-accent-ink underline-offset-2 hover:underline"
            >
              {gettext("Open the current page")}
              <span class="font-mono font-normal text-ink-subtle">{scenario.legacy_path}</span>
              <.icon name="hero-arrow-right-micro" class="size-4" />
            </a>
          </article>
        </li>
      </ul>
    </Layouts.app>
    """
  end
end
