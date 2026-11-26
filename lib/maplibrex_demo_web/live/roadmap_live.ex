defmodule MaplibrexDemoWeb.RoadmapLive do
  @moduledoc """
  What does not fully work yet, and what the library is working on next.

  The list is the catalogue filtered to limited and planned components, so it
  changes whenever a status does. The next-release section comes from
  `MaplibrexDemoWeb.Catalogue.next_release/0`.
  """
  use MaplibrexDemoWeb, :live_view

  alias MaplibrexDemoWeb.{Catalogue, LibraryDocs}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, gettext("Roadmap"))}
  end

  @impl true
  def render(assigns) do
    families =
      for family <- Catalogue.families(),
          open = Enum.reject(family.components, &(&1.status == :stable)),
          open != [] do
        %{family | components: open}
      end

    assigns =
      assign(assigns,
        families: families,
        counts: Catalogue.status_counts(),
        version: LibraryDocs.version(),
        next_release: Catalogue.next_release()
      )

    ~H"""
    <Layouts.app
      flash={@flash}
      locale={@locale}
      current_path={@current_path}
      query={@query}
      section={:roadmap}
    >
      <header class="max-w-measure">
        <h1 class="text-display font-black tracking-tight">{gettext("Roadmap")}</h1>
        <p class="mt-3 text-lead text-ink-muted">
          {gettext(
            "What does not fully work in MaplibreX %{version}, and what the library is working on next. Every status that is not stable links to the library issue that explains it.",
            version: @version
          )}
        </p>
      </header>

      <section id="statuses" class="mt-10" aria-labelledby="statuses-heading">
        <h2 id="statuses-heading" class="text-heading font-black">{gettext("Statuses")}</h2>
        <dl class="mt-4 grid max-w-measure gap-y-3 text-body">
          <div
            :for={status <- [:stable, :limited, :planned]}
            class="grid grid-cols-[7.5rem_1fr] gap-x-4"
          >
            <dt>
              <.status_badge status={status} />
            </dt>
            <dd class="text-ink-muted">
              {status_meaning(status)}
              <span class="text-ink-subtle tabular-nums">
                ({ngettext("1 component", "%{count} components", @counts[status])})
              </span>
            </dd>
          </div>
        </dl>
      </section>

      <section id="roadmap-components" class="mt-12" aria-labelledby="roadmap-components-heading">
        <h2 id="roadmap-components-heading" class="text-heading font-black">
          {gettext("Limited and planned components")}
        </h2>

        <section
          :for={family <- @families}
          id={"roadmap-family-#{family.id}"}
          class="mt-7"
          aria-labelledby={"roadmap-family-#{family.id}-heading"}
        >
          <h3
            id={"roadmap-family-#{family.id}-heading"}
            class="text-label font-bold tracking-[0.1em] text-ink-subtle uppercase"
          >
            {family.label}
          </h3>
          <ul class="mt-2 divide-y divide-line border-y border-line">
            <li
              :for={component <- family.components}
              id={"roadmap-item-#{component.name}"}
              class="grid gap-x-6 gap-y-2 py-3 md:grid-cols-[minmax(0,17.5rem)_minmax(0,1fr)]"
            >
              <div class="flex flex-wrap items-center gap-2">
                <.link
                  navigate={~p"/components/#{component.name}"}
                  class="font-bold text-ink underline-offset-2 hover:text-accent-ink hover:underline"
                >
                  {component.name}
                </.link>
                <.status_badge status={component.status} />
              </div>
              <.issue_list issues={component.issues} class="text-ui" />
            </li>
          </ul>
        </section>
      </section>

      <section id="next-release" class="mt-12" aria-labelledby="next-release-heading">
        <h2 id="next-release-heading" class="text-heading font-black">
          {gettext("In progress for %{version}", version: @next_release.version)}
        </h2>
        <p class="mt-2 max-w-measure text-body text-ink-muted">
          {gettext(
            "The library's next release reworks how layers, sources and terrain join and leave the map. The work is under way in the library repository; no release date has been announced."
          )}
        </p>
        <ul class="mt-4 max-w-measure space-y-2.5 text-body">
          <li :for={item <- @next_release.items} class="flex flex-wrap items-baseline gap-x-2">
            <.icon name="hero-arrow-path-micro" class="size-4 shrink-0 self-center text-ink-subtle" />
            <span><.rich_text text={item.text} /></span>
            <span class="inline-flex gap-1.5">
              <.issue_link :for={number <- item.issues} number={number} />
            </span>
          </li>
        </ul>
        <p class="mt-6 text-ui">
          <a
            href={Catalogue.issues_url()}
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center gap-1 font-bold text-accent-ink underline-offset-2 hover:underline"
          >
            {gettext("All open issues of the library")}
            <.icon name="hero-arrow-up-right-micro" class="size-4" />
          </a>
        </p>
      </section>
    </Layouts.app>
    """
  end

  defp status_meaning(:stable), do: gettext("Works as documented.")

  defp status_meaning(:limited),
    do: gettext("Works, but an open issue documents a part of its behaviour that does not.")

  defp status_meaning(:planned), do: gettext("Cannot be used yet; its issue tracks the fix.")
end
