defmodule MaplibrexDemoWeb.ScenarioLive do
  @moduledoc """
  One scenario at `/scenarios/:id`: several components combined into one
  working map.

  The header gives the title, whether the data is sample data, the summary,
  the components it uses and the library issues it depends on. The scenario
  runs below, with its template and its module underneath, read at compile
  time, so the code on the page is the code that runs.
  """
  use MaplibrexDemoWeb, :live_view

  alias MaplibrexDemoWeb.{Catalogue, NotFoundError}
  alias MaplibrexDemoWeb.Examples.Sources

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Catalogue.fetch_scenario(id) do
      {:ok, scenario} ->
        {previous, next} = Catalogue.scenario_neighbours(scenario.id)

        {:ok,
         socket
         |> assign(:scenario, scenario)
         |> assign(:previous, previous)
         |> assign(:next, next)
         |> assign(:sources, Sources.files(scenario.module))
         |> assign(:page_title, scenario.title)}

      :error ->
        raise NotFoundError, "no scenario is called #{inspect(id)}"
    end
  end

  # MaplibrexDemoWeb.Examples.Plumbing reports every library event the
  # scenario receives; this page has no Events tab to show them in.
  @impl true
  def handle_info({:example_event, _event, _payload}, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      locale={@locale}
      current_path={@current_path}
      query={@query}
      section={:scenarios}
    >
      <header>
        <div class="flex flex-wrap items-center gap-x-3 gap-y-2">
          <h1 id="scenario-title" class="text-display font-black tracking-tight">
            {@scenario.title}
          </h1>
          <.sample_data_badge :if={@scenario.sample_data} id="scenario-sample-data" />
        </div>
        <p id="scenario-summary" class="mt-2 max-w-measure text-lead text-ink-muted">
          {@scenario.summary}
        </p>
        <.component_chips
          id="scenario-components"
          names={@scenario.components}
          class="mt-4"
        />
      </header>

      <section
        :if={@scenario.notes != []}
        id="scenario-notes"
        class="mt-5 max-w-measure rounded-panel border border-line bg-surface px-4 py-3 text-ui"
        aria-labelledby="scenario-notes-heading"
      >
        <h2 id="scenario-notes-heading" class="flex items-center gap-1.5 font-bold">
          <.status_mark status={:limited} />
          {gettext("What it depends on")}
        </h2>
        <.issue_list issues={@scenario.notes} class="mt-1.5" />
      </section>

      <section id="scenario-preview" class="mt-7" aria-label={gettext("Running scenario")}>
        <div class="overflow-hidden rounded-panel border border-line bg-canvas">
          {live_render(@socket, @scenario.module,
            id: "scenario-#{@scenario.id}-live",
            session: %{"locale" => @locale}
          )}
        </div>

        <.code_block
          :for={file <- @sources}
          id={"scenario-source-#{String.replace(file.name, ".", "-")}"}
          code={file.source}
          html={file.html}
          language={file.language}
          title={file.path}
          collapse
          class="mt-4"
        />
      </section>

      <.pager
        id="scenario"
        label={gettext("Previous and next scenario")}
        previous={page_link(@previous)}
        next={page_link(@next)}
      />
    </Layouts.app>
    """
  end

  defp page_link(nil), do: nil
  defp page_link(scenario), do: %{name: scenario.title, path: ~p"/scenarios/#{scenario.id}"}
end
