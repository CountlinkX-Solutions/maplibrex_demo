defmodule MaplibrexDemoWeb.ScenariosLive do
  @moduledoc """
  Scenarios: several components combined into one working map, each
  linking its page at `/scenarios/:id`.
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
            "A scenario combines several components into one working map, with the code that produces it."
          )}
        </p>
      </header>

      <ul class="mt-10 divide-y divide-line border-y border-line">
        <li :for={scenario <- @scenarios} id={"scenario-#{scenario.id}"} class="py-6">
          <article aria-labelledby={"scenario-#{scenario.id}-heading"}>
            <div class="flex flex-wrap items-center gap-x-3 gap-y-2">
              <h2 id={"scenario-#{scenario.id}-heading"} class="text-heading font-black">
                <.link
                  navigate={~p"/scenarios/#{scenario.id}"}
                  class="underline-offset-4 hover:text-accent-ink hover:underline"
                >
                  {scenario.title}
                </.link>
              </h2>
              <.sample_data_badge :if={scenario.sample_data} />
            </div>

            <p class="mt-2 max-w-measure text-body text-ink-muted">{scenario.summary}</p>

            <p :if={scenario.sample_data} class="mt-1 max-w-measure text-ui text-ink-subtle">
              {gettext("It draws data generated for the demo, not real measurements.")}
            </p>

            <.component_chips names={scenario.components} class="mt-3" />

            <.link
              navigate={~p"/scenarios/#{scenario.id}"}
              class="mt-4 inline-flex items-center gap-1.5 text-ui font-bold text-accent-ink underline-offset-2 hover:underline"
            >
              {gettext("Open the scenario")}
              <.icon name="hero-arrow-right-micro" class="size-4" />
            </.link>
          </article>
        </li>
      </ul>
    </Layouts.app>
    """
  end
end
