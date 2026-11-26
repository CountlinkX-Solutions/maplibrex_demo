defmodule MaplibrexDemoWeb.ComponentsLive do
  @moduledoc """
  Every component of the catalogue, family by family, with its summary and
  status. The "Components" entry of the top bar.
  """
  use MaplibrexDemoWeb, :live_view

  alias MaplibrexDemoWeb.{Catalogue, LibraryDocs}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, gettext("Components"))}
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        families: Catalogue.families(),
        total: length(Catalogue.components()),
        version: LibraryDocs.version()
      )

    ~H"""
    <Layouts.app
      flash={@flash}
      locale={@locale}
      current_path={@current_path}
      query={@query}
      section={:components}
    >
      <header class="max-w-measure">
        <h1 class="text-display font-black tracking-tight">{gettext("Components")}</h1>
        <p class="mt-3 text-lead text-ink-muted">
          {gettext(
            "The %{count} components of MaplibreX %{version}, in the families the library groups them in. Each page lists the component's attributes and events, and runs its example when there is one.",
            count: @total,
            version: @version
          )}
        </p>
      </header>

      <section
        :for={family <- @families}
        id={"family-#{family.id}"}
        class="mt-12 scroll-mt-[calc(var(--spacing-topbar)+1.5rem)]"
        aria-labelledby={"family-#{family.id}-heading"}
      >
        <h2 id={"family-#{family.id}-heading"} class="flex items-baseline gap-3">
          <span class="text-heading font-black">{family.label}</span>
          <span class="text-ui text-ink-subtle tabular-nums">
            {ngettext("1 component", "%{count} components", family.count)}
          </span>
        </h2>

        <ul class="mt-4 divide-y divide-line border-y border-line">
          <li
            :for={component <- family.components}
            id={"component-row-#{component.name}"}
            class="grid gap-x-6 gap-y-1 py-3 md:grid-cols-[minmax(0,13.5rem)_minmax(0,1fr)_auto] md:items-baseline"
          >
            <.link
              navigate={~p"/components/#{component.name}"}
              class="font-bold text-ink underline-offset-2 hover:text-accent-ink hover:underline"
            >
              {component.name}
            </.link>
            <p class="text-ui text-ink-muted md:order-none">{component.summary}</p>
            <.status_badge status={component.status} class="justify-self-start md:justify-self-end" />
          </li>
        </ul>
      </section>
    </Layouts.app>
    """
  end
end
