defmodule MaplibrexDemoWeb.ComponentLive do
  @moduledoc """
  One component of the catalogue: its name, status and summary, why it is
  limited or planned when it is, and the way to the previous and next one.
  """
  use MaplibrexDemoWeb, :live_view

  alias MaplibrexDemoWeb.{Catalogue, NotFoundError}

  @impl true
  def mount(%{"name" => name}, _session, socket) do
    case Catalogue.fetch(name) do
      {:ok, component} ->
        {previous, next} = Catalogue.neighbours(component.name)

        {:ok,
         socket
         |> assign(:component, component)
         |> assign(:previous, previous)
         |> assign(:next, next)
         |> assign(:page_title, Atom.to_string(component.name))}

      :error ->
        raise NotFoundError, "no component is called #{inspect(name)}"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      locale={@locale}
      current_path={@current_path}
      query={@query}
      section={:components}
      current_component={@component.name}
    >
      <header>
        <div class="flex flex-wrap items-center gap-x-3 gap-y-2">
          <h1 id="component-title" class="text-display font-black tracking-tight break-all">
            {@component.name}
          </h1>
          <.status_badge id="component-status" status={@component.status} />
        </div>
        <p id="component-summary" class="mt-2 max-w-measure text-lead text-ink-muted">
          {@component.summary}
        </p>
      </header>

      <section
        :if={@component.issues != []}
        id="component-issues"
        class="mt-5 max-w-measure rounded-panel border border-line bg-surface px-4 py-3 text-ui"
        aria-labelledby="component-issues-heading"
      >
        <h2 id="component-issues-heading" class="flex items-center gap-1.5 font-bold">
          <.status_mark status={@component.status} />
          {why_heading(@component.status)}
        </h2>
        <.issue_list issues={@component.issues} class="mt-1.5" />
      </section>

      <nav
        aria-label={gettext("Previous and next component")}
        class="mt-16 grid gap-3 border-t border-line pt-6 sm:grid-cols-2"
      >
        <.link
          :if={@previous}
          id="component-previous"
          navigate={~p"/components/#{@previous.name}"}
          class="group rounded-panel border border-line px-4 py-3 hover:border-line-strong hover:bg-surface"
        >
          <span class="block text-label text-ink-subtle">{gettext("Previous")}</span>
          <span class="mt-0.5 flex items-center gap-1.5 font-bold group-hover:text-accent-ink">
            <.icon name="hero-arrow-left-micro" class="size-4" />{@previous.name}
          </span>
        </.link>
        <.link
          :if={@next}
          id="component-next"
          navigate={~p"/components/#{@next.name}"}
          class="group rounded-panel border border-line px-4 py-3 text-right hover:border-line-strong hover:bg-surface sm:col-start-2"
        >
          <span class="block text-label text-ink-subtle">{gettext("Next")}</span>
          <span class="mt-0.5 flex items-center justify-end gap-1.5 font-bold group-hover:text-accent-ink">
            {@next.name}<.icon name="hero-arrow-right-micro" class="size-4" />
          </span>
        </.link>
      </nav>
    </Layouts.app>
    """
  end

  defp why_heading(:limited), do: gettext("Why it is limited")
  defp why_heading(:planned), do: gettext("Why it is planned")
end
