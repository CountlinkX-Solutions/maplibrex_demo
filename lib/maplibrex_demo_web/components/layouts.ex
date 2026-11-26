defmodule MaplibrexDemoWeb.Layouts do
  @moduledoc """
  The layouts of the demo.

    * `root.html.heex` — the HTML document every page shares.
    * `app/1` — the catalogue shell: top bar, component sidebar (a drawer on
      narrow screens) and the main column. Every page of the `:catalogue`
      live session renders inside it.
  """
  use MaplibrexDemoWeb, :html

  alias MaplibrexDemoWeb.{Catalogue, LibraryDocs}

  embed_templates "layouts/*"

  @sections [nil, :overview, :components, :scenarios, :roadmap]

  @doc """
  Renders the catalogue shell around a page.

  The navigation assigns (`locale`, `current_path`, `query`) come from
  `MaplibrexDemoWeb.LocaleHook` and `MaplibrexDemoWeb.CatalogueNav`.

  ## Examples

      <Layouts.app
        flash={@flash}
        locale={@locale}
        current_path={@current_path}
        query={@query}
        section={:components}
        current_component={:map}
      >
        <h1>map</h1>
      </Layouts.app>
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :locale, :string, required: true
  attr :current_path, :string, required: true, doc: "where the locale switch returns to"
  attr :query, :string, default: "", doc: "the component filter's text"

  attr :section, :atom,
    default: nil,
    values: @sections,
    doc: "the top-level section to mark as current"

  attr :current_component, :atom, default: nil, doc: "the component to mark in the sidebar"

  attr :page_sections, :list,
    default: [],
    doc: """
    the page's sections for the "On this page" rail beside the main column
    on wide screens, as `%{id: heading_id, label: label}`, with `level: 3`
    for a subsection; no rail when empty
    """

  slot :inner_block, required: true

  def app(assigns) do
    assigns =
      assign(assigns,
        families: filtered_families(assigns.query),
        version: LibraryDocs.version()
      )

    ~H"""
    <a
      href="#main"
      class="sr-only rounded-ui bg-canvas px-3 py-2 text-ui font-bold text-ink shadow-overlay focus:not-sr-only focus:fixed focus:top-3 focus:left-4 focus:z-50"
    >
      {gettext("Skip to content")}
    </a>

    <header id="topbar" class="sticky top-0 z-30 h-topbar border-b border-line bg-canvas">
      <div class="flex h-full items-center gap-3 px-4 sm:px-6 lg:gap-6 lg:px-7">
        <button
          id="nav-drawer-open"
          type="button"
          class="-ml-1.5 inline-flex size-9 cursor-pointer items-center justify-center rounded-ui text-ink-muted hover:bg-surface hover:text-ink lg:hidden"
          aria-controls="nav-drawer"
          aria-label={gettext("Open navigation")}
          phx-click={JS.dispatch("app:dialog-open", to: "#nav-drawer")}
        >
          <.icon name="hero-bars-3" class="size-5" />
        </button>

        <div class="flex items-center gap-2.5">
          <.link
            navigate={~p"/"}
            id="wordmark"
            class="rounded-ui text-[1.375rem] leading-none font-black tracking-tight text-accent-ink"
          >
            MaplibreX
          </.link>
          <span
            id="library-version"
            class="rounded-[5px] bg-surface px-2 py-1 font-mono text-label font-semibold text-ink-muted"
            title={gettext("Version of the MaplibreX library this demo runs")}
          >
            v{@version}
          </span>
        </div>

        <nav aria-label={gettext("Sections")} class="ml-2 hidden h-full items-stretch md:flex">
          <.section_link
            id="nav-components"
            navigate={~p"/components"}
            current={@section == :components}
          >
            {gettext("Components")}
          </.section_link>
          <.section_link id="nav-scenarios" navigate={~p"/scenarios"} current={@section == :scenarios}>
            {gettext("Scenarios")}
          </.section_link>
          <.section_link id="nav-roadmap" navigate={~p"/roadmap"} current={@section == :roadmap}>
            {gettext("Roadmap")}
          </.section_link>
        </nav>

        <div class="ml-auto hidden items-center gap-3 lg:flex">
          <.component_filter id="component-filter" query={@query} shortcut class="w-80" />
          <.locale_switch link_prefix="locale" locale={@locale} current_path={@current_path} />
          <.theme_switch id="theme-switch" />
        </div>
      </div>
    </header>

    <div class="lg:grid lg:grid-cols-[var(--spacing-sidebar)_minmax(0,1fr)]">
      <aside
        id="sidebar"
        class="sticky top-topbar hidden h-[calc(100dvh-var(--spacing-topbar))] overflow-y-auto border-r border-line bg-surface px-[18px] pt-5 pb-12 lg:block"
      >
        <.component_tree
          id="sidebar"
          families={@families}
          query={@query}
          section={@section}
          current_component={@current_component}
        />
      </aside>

      <main id="main" class="min-w-0 px-4 pt-8 pb-24 sm:px-8 lg:px-12 lg:pt-[34px]">
        <%= if @page_sections == [] do %>
          <div class="max-w-page">
            {render_slot(@inner_block)}
          </div>
        <% else %>
          <div class="max-w-page xl:grid xl:max-w-[calc(var(--container-page)+var(--spacing-rail)+3rem)] xl:grid-cols-[minmax(0,1fr)_var(--spacing-rail)] xl:gap-x-12">
            <div class="min-w-0">
              {render_slot(@inner_block)}
            </div>
            <.page_rail sections={@page_sections} />
          </div>
        <% end %>
      </main>
    </div>

    <dialog
      id="nav-drawer"
      aria-label={gettext("Navigation")}
      class="drawer m-0 h-dvh max-h-dvh w-[min(20rem,88vw)] max-w-none overflow-y-auto border-r border-line bg-surface p-0 text-ink shadow-overlay backdrop:bg-ink/40"
      phx-mounted={JS.ignore_attributes(["open"])}
      data-close-on-backdrop
    >
      <div class="flex min-h-full flex-col px-[18px] pt-3 pb-8">
        <div class="flex h-12 items-center justify-between">
          <span class="text-[1.25rem] font-black tracking-tight text-accent-ink">MaplibreX</span>
          <button
            id="nav-drawer-close"
            type="button"
            class="-mr-1.5 inline-flex size-9 cursor-pointer items-center justify-center rounded-ui text-ink-muted hover:bg-surface-hover hover:text-ink"
            aria-label={gettext("Close navigation")}
            phx-click={JS.dispatch("app:dialog-close", to: "#nav-drawer")}
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>

        <nav aria-label={gettext("Sections")} class="mt-2 flex flex-col md:hidden">
          <.link
            :for={{id, path, label, section} <- section_links()}
            id={"drawer-#{id}"}
            navigate={path}
            aria-current={@section == section && "page"}
            class={[
              "rounded-ui px-2.5 py-[7px] text-nav",
              if(@section == section,
                do: "bg-accent-soft font-bold text-accent-ink",
                else: "text-ink hover:bg-surface-hover"
              )
            ]}
          >
            {label}
          </.link>
        </nav>

        <.component_filter id="component-filter-drawer" query={@query} class="mt-4 w-full" />

        <div class="mt-1">
          <.component_tree
            id="drawer"
            families={@families}
            query={@query}
            section={@section}
            current_component={@current_component}
          />
        </div>

        <div class="mt-auto flex items-center gap-3 border-t border-line pt-5">
          <.locale_switch link_prefix="drawer-locale" locale={@locale} current_path={@current_path} />
          <.theme_switch id="theme-switch-drawer" />
        </div>
      </div>
    </dialog>

    <.flash_group flash={@flash} />
    """
  end

  defp section_links do
    [
      {"nav-components", ~p"/components", gettext("Components"), :components},
      {"nav-scenarios", ~p"/scenarios", gettext("Scenarios"), :scenarios},
      {"nav-roadmap", ~p"/roadmap", gettext("Roadmap"), :roadmap}
    ]
  end

  # Families with only the components the filter matches; empty ones drop out.
  defp filtered_families(query) do
    matches = MapSet.new(Catalogue.search(query), & &1.name)

    for family <- Catalogue.families(),
        members = Enum.filter(family.components, &MapSet.member?(matches, &1.name)),
        members != [] do
      %{family | components: members}
    end
  end

  # The "On this page" rail: plain anchors to the page's headings, so it
  # works without JavaScript. The PageRail hook (assets/js/page_rail.js)
  # marks the section being read; phx-update="ignore" keeps that mark when
  # LiveView patches the page.
  attr :sections, :list, required: true

  defp page_rail(assigns) do
    ~H"""
    <aside class="hidden xl:block">
      <nav
        id="page-rail"
        phx-hook="PageRail"
        phx-update="ignore"
        aria-labelledby="page-rail-title"
        class="sticky top-[calc(var(--spacing-topbar)+2.125rem)] max-h-[calc(100dvh-var(--spacing-topbar)-4.25rem)] overflow-y-auto pb-6"
      >
        <p
          id="page-rail-title"
          class="text-label font-bold tracking-[0.1em] text-ink-subtle uppercase"
        >
          {gettext("On this page")}
        </p>
        <ul class="mt-3 border-l border-line">
          <li :for={section <- @sections}>
            <a
              href={"##{section.id}"}
              class={[
                "-ml-px block border-l border-transparent py-1 pr-2 text-ui text-ink-muted hover:text-ink focus-visible:-outline-offset-2",
                "aria-[current=true]:border-accent-ink aria-[current=true]:font-bold aria-[current=true]:text-accent-ink",
                if(Map.get(section, :level, 2) == 3, do: "pl-6", else: "pl-3")
              ]}
            >
              {section.label}
            </a>
          </li>
        </ul>
      </nav>
    </aside>
    """
  end

  attr :id, :string, required: true
  attr :navigate, :string, required: true
  attr :current, :boolean, default: false
  slot :inner_block, required: true

  defp section_link(assigns) do
    ~H"""
    <.link
      id={@id}
      navigate={@navigate}
      aria-current={@current && "page"}
      class={[
        "relative inline-flex items-center px-3 text-nav hover:text-ink",
        if(@current,
          do:
            "font-bold text-accent-ink after:absolute after:inset-x-3 after:-bottom-px after:h-0.5 after:bg-accent-ink",
          else: "text-ink-muted"
        )
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  The tree of components grouped by family, with the current item filled and
  a status mark on every component that is not stable.

  Rendered twice (sidebar and drawer), so every id carries the `id` prefix.
  """
  attr :id, :string, required: true
  attr :families, :list, required: true
  attr :query, :string, default: ""
  attr :section, :atom, default: nil
  attr :current_component, :atom, default: nil

  def component_tree(assigns) do
    ~H"""
    <nav aria-label={gettext("Components")}>
      <.link
        id={"#{@id}-overview"}
        navigate={~p"/"}
        aria-current={@section == :overview && "page"}
        class={tree_link_class(@section == :overview)}
      >
        {gettext("Overview")}
      </.link>

      <section :for={family <- @families} id={"#{@id}-family-#{family.id}"} class="mt-5">
        <h2
          id={"#{@id}-family-#{family.id}-label"}
          class="mx-2.5 mb-1.5 text-label font-bold tracking-[0.1em] text-ink-subtle uppercase"
        >
          {family.label}
        </h2>
        <ul aria-labelledby={"#{@id}-family-#{family.id}-label"}>
          <li :for={component <- family.components} data-component={component.name}>
            <.link
              id={"#{@id}-item-#{component.name}"}
              navigate={~p"/components/#{component.name}"}
              aria-current={@current_component == component.name && "page"}
              class={tree_link_class(@current_component == component.name)}
            >
              <span class="min-w-0 truncate">{component.name}</span>
              <%= if component.status != :stable do %>
                <.status_mark
                  status={component.status}
                  class={[
                    "ml-auto [&_span]:size-3.5",
                    @current_component == component.name && "[&_span]:text-on-accent"
                  ]}
                />
                <span class="sr-only">({status_word(component.status)})</span>
              <% end %>
            </.link>
          </li>
        </ul>
      </section>

      <div
        :if={@families == []}
        id={"#{@id}-empty"}
        class="mx-2.5 mt-5 rounded-panel border border-dashed border-line-strong px-3 py-4 text-ui text-ink-muted"
      >
        <p>{gettext("No component name contains “%{query}”.", query: @query)}</p>
        <button
          type="button"
          phx-click="clear_filter"
          class="mt-2 cursor-pointer font-bold text-accent-ink underline-offset-2 hover:underline"
        >
          {gettext("Clear the filter")}
        </button>
      </div>
    </nav>
    """
  end

  defp tree_link_class(true) do
    "flex items-center gap-2 rounded-ui bg-accent px-2.5 py-[7px] text-nav font-bold text-on-accent"
  end

  defp tree_link_class(false) do
    "flex items-center gap-2 rounded-ui px-2.5 py-[7px] text-nav text-ink hover:bg-surface-hover"
  end

  @doc """
  The component filter: narrows the sidebar as you type; Enter opens the
  first match. Its events are handled by `MaplibrexDemoWeb.CatalogueNav`.
  """
  attr :id, :string, required: true
  attr :query, :string, default: ""
  attr :shortcut, :boolean, default: false, doc: "show the / key hint"
  attr :class, :any, default: nil

  def component_filter(assigns) do
    assigns = assign(assigns, :form, to_form(%{"q" => assigns.query}))

    ~H"""
    <.form
      for={@form}
      id={@id}
      role="search"
      phx-change="filter_components"
      phx-submit="open_first_match"
      class={["relative", @class]}
    >
      <.icon
        name="hero-magnifying-glass-micro"
        class="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-ink-subtle"
      />
      <.input
        field={@form[:q]}
        id={"#{@id}-input"}
        type="search"
        wrapper_class=""
        placeholder={gettext("Search components")}
        aria-label={gettext("Search components")}
        autocomplete="off"
        spellcheck="false"
        phx-debounce="80"
        class="h-9 w-full rounded-ui border border-line-strong bg-canvas pr-9 pl-9 text-ui text-ink placeholder:text-ink-subtle"
      />
      <kbd
        :if={@shortcut}
        class="pointer-events-none absolute top-1/2 right-2.5 -translate-y-1/2 rounded-[4px] border border-line bg-surface px-1.5 font-mono text-label leading-5 text-ink-subtle"
        title={gettext("Press / to search")}
      >
        /
      </kbd>
    </.form>
    """
  end

  @doc """
  English or Spanish. The links go through `LocaleController`, which stores
  the choice and returns to `current_path`.
  """
  attr :link_prefix, :string, required: true
  attr :locale, :string, required: true
  attr :current_path, :string, required: true

  def locale_switch(assigns) do
    ~H"""
    <div
      role="group"
      aria-label={gettext("Language")}
      class="flex items-center rounded-ui border border-line bg-surface p-0.5"
    >
      <a
        :for={{code, name} <- [{"en", "English"}, {"es", "Español"}]}
        id={"#{@link_prefix}-#{code}"}
        href={~p"/locale?#{[locale: code, return_to: @current_path]}"}
        hreflang={code}
        lang={code}
        title={name}
        aria-current={@locale == code && "true"}
        class={[
          "inline-flex h-7 min-w-9 items-center justify-center rounded-[5px] px-2 text-label font-bold",
          if(@locale == code,
            do: "bg-canvas text-ink shadow-sm",
            else: "text-ink-subtle hover:text-ink"
          )
        ]}
      >
        {String.upcase(code)}
      </a>
    </div>
    """
  end

  @doc """
  System, light or dark. The choice is applied in the browser by
  `assets/js/theme.js`; the pressed look follows `<html data-theme>`, so the
  server never renders a stale state.
  """
  attr :id, :string, required: true

  def theme_switch(assigns) do
    ~H"""
    <div
      id={@id}
      phx-update="ignore"
      role="group"
      aria-label={gettext("Theme")}
      class="flex items-center rounded-ui border border-line bg-surface p-0.5"
    >
      <button
        :for={{choice, icon, label} <- theme_choices()}
        type="button"
        data-theme-choice={choice}
        phx-click={JS.dispatch("app:set-theme")}
        aria-label={label}
        title={label}
        class={[
          "inline-flex size-7 cursor-pointer items-center justify-center rounded-[5px] text-ink-subtle hover:text-ink",
          theme_pressed_class(choice)
        ]}
      >
        <.icon name={icon} class="size-4" />
      </button>
    </div>
    """
  end

  defp theme_choices do
    [
      {"system", "hero-computer-desktop-micro", gettext("Use the system theme")},
      {"light", "hero-sun-micro", gettext("Use the light theme")},
      {"dark", "hero-moon-micro", gettext("Use the dark theme")}
    ]
  end

  # Written out in full so Tailwind finds every class.
  defp theme_pressed_class("system"),
    do:
      "[html:not([data-theme])_&]:bg-canvas [html:not([data-theme])_&]:text-ink [html:not([data-theme])_&]:shadow-sm"

  defp theme_pressed_class("light"),
    do:
      "[html[data-theme=light]_&]:bg-canvas [html[data-theme=light]_&]:text-ink [html[data-theme=light]_&]:shadow-sm"

  defp theme_pressed_class("dark"),
    do:
      "[html[data-theme=dark]_&]:bg-canvas [html[data-theme=dark]_&]:text-ink [html[data-theme=dark]_&]:shadow-sm"

  @doc """
  Shows the flash group with standard titles and content, including the
  notices for a lost connection.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div
      id={@id}
      aria-live="polite"
      class="pointer-events-none fixed top-[calc(var(--spacing-topbar)+0.75rem)] right-4 z-50 flex w-[min(24rem,calc(100vw-2rem))] flex-col gap-2"
    >
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("Connection lost")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Reconnecting. The page cannot update until the connection is back.")}
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("The server is not responding")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Reconnecting. If the demo server was stopped, start it again with mix phx.server.")}
      </.flash>
    </div>
    """
  end
end
