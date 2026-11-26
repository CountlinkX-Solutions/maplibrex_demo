defmodule MaplibrexDemoWeb.OverviewLive do
  @moduledoc """
  The demo's home: what MaplibreX is, how to install it, how much of it the
  catalogue covers, and the ways into the rest of the demo.

  The install steps condense the installation section of the library's
  README, which the page links to for the rest (a `path:` dependency,
  deck.gl, the reasons); the code in them and the minimal template are
  copied from it. Keep them in step with it, except the dependency, which
  names the library's `main` branch the demo itself runs. Every count is
  computed from `MaplibrexDemoWeb.Catalogue`.
  """
  use MaplibrexDemoWeb, :live_view

  alias MaplibrexDemoWeb.{Catalogue, LibraryDocs}

  @readme_install_url "https://github.com/CountlinkX-Solutions/maplibrex#installation"

  @dependency ~S'''
  def deps do
    [
      {:maplibrex, github: "CountlinkX-Solutions/maplibrex", branch: "main"}
    ]
  end
  '''

  @npm ~S'''
  npm install --prefix assets maplibre-gl
  '''

  @hooks ~S'''
  import { MapHooks } from "maplibrex"

  const liveSocket = new LiveSocket("/live", Socket, {
    longPollFallbackMs: 2500,
    params: {_csrf_token: csrfToken},
    hooks: {...colocatedHooks, ...MapHooks},
  })
  '''

  @esbuild ~S'''
  config :esbuild,
    version: "0.25.4",
    my_app: [
      args:
        ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js
           --external:/fonts/* --external:/images/* --alias:@=.
           --external:@deck.gl/*),
      cd: Path.expand("../assets", __DIR__),
      env: %{
        "NODE_PATH" => [
          Path.expand("../deps", __DIR__),
          Mix.Project.build_path(),
          Path.expand("../assets/node_modules", __DIR__)
        ]
      }
    ]
  '''

  @worker_copy ~S'''
  defp copy_maplibre_worker(_args) do
    dest = "priv/static/assets/js"
    File.mkdir_p!(dest)

    for file <- ~w(maplibre-gl-worker.mjs maplibre-gl-shared.mjs) do
      File.cp!(Path.join("assets/node_modules/maplibre-gl/dist", file), Path.join(dest, file))
    end
  end
  '''

  @worker_url ~S'''
  import { getVersion, setWorkerUrl } from "maplibre-gl"

  setWorkerUrl(`/assets/js/maplibre-gl-worker.mjs?v=${getVersion()}`)
  '''

  @stylesheets ~S'''
  @import "maplibre-gl/dist/maplibre-gl.css";
  @import "../../deps/maplibrex/assets/css/maplibrex.css";
  '''

  @import ~S'''
  defmodule MyAppWeb.MapLive do
    use MyAppWeb, :live_view
    import MaplibreX.Components

    # ...

    def handle_event(_event, _params, socket), do: {:noreply, socket}
  end
  '''

  @minimal ~S'''
  def render(assigns) do
    ~H"""
    <.map id="map" center={@center} zoom={@zoom} class="h-96 w-full" />
    <.navigation_control id="nav" map_id="map" position="top-left" />

    <.marker :for={city <- @cities} id={city.id} map_id="map"
             lng_lat={city.coords} color="#22d3ee" popup_text={city.name} />
    """
  end

  def handle_event("map:moved", %{"center" => center, "zoom" => zoom}, socket) do
    {:noreply, assign(socket, center: center, zoom: zoom)}
  end

  # The components push every event they emit; ignore the ones you do not use.
  def handle_event(_event, _params, socket), do: {:noreply, socket}
  '''

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, gettext("Overview"))}
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        families: Catalogue.families(),
        totals: Catalogue.status_counts(),
        total: length(Catalogue.components()),
        version: LibraryDocs.version(),
        readme_install_url: @readme_install_url,
        snippets: %{
          dependency: String.trim_trailing(@dependency),
          npm: String.trim_trailing(@npm),
          hooks: String.trim_trailing(@hooks),
          esbuild: String.trim_trailing(@esbuild),
          worker_copy: String.trim_trailing(@worker_copy),
          worker_url: String.trim_trailing(@worker_url),
          stylesheets: String.trim_trailing(@stylesheets),
          import: String.trim_trailing(@import),
          minimal: String.trim_trailing(@minimal)
        }
      )

    ~H"""
    <Layouts.app
      flash={@flash}
      locale={@locale}
      current_path={@current_path}
      query={@query}
      section={:overview}
      page_sections={[
        %{id: "install-heading", label: gettext("Install")},
        %{id: "minimal-heading", label: gettext("A minimal map")},
        %{id: "families-heading", label: gettext("Components by family")},
        %{id: "next-heading", label: gettext("Where to go next")}
      ]}
    >
      <article id="overview">
        <header class="max-w-measure">
          <h1 class="text-display font-black tracking-tight">MaplibreX</h1>
          <p class="mt-3 text-lead text-ink-muted">
            {gettext(
              "MapLibre GL JS as declarative Phoenix LiveView components. The map is declared in HEEx and driven from the server: assigns change the map, map events arrive in handle_event/3, and the application writes no JavaScript."
            )}
          </p>
          <p class="mt-3 text-body text-ink-muted">
            {gettext(
              "This demo runs MaplibreX %{version}. It lists all %{count} components with their status, and shows each working example next to the code that produces it.",
              version: @version,
              count: @total
            )}
          </p>
          <div class="mt-6 flex flex-wrap gap-3">
            <.link
              id="overview-browse"
              navigate={~p"/components"}
              class="inline-flex h-10 items-center gap-2 rounded-ui bg-accent px-4 text-ui font-bold text-on-accent hover:bg-accent-hover"
            >
              {gettext("Browse the components")}
              <.icon name="hero-arrow-right-micro" class="size-4" />
            </.link>
            <.link
              id="overview-example"
              navigate={~p"/components/map"}
              class="inline-flex h-10 items-center gap-2 rounded-ui border border-line-strong px-4 text-ui font-bold text-ink hover:bg-surface"
            >
              {gettext("Open the map example")}
            </.link>
          </div>
        </header>

        <%!-- Inline code here is typed as is: a flag or a command never breaks
             across lines. --%>
        <section
          id="install"
          class="mt-14 [&_.inline-code]:whitespace-nowrap"
          aria-labelledby="install-heading"
        >
          <h2 id="install-heading" class="text-heading font-black">{gettext("Install")}</h2>
          <p class="mt-2 max-w-measure text-body text-ink-muted">
            {gettext("Requires Elixir 1.15 or later and Phoenix LiveView 1.0 or later.")}
            <.rich_text text={
              gettext(
                "The steps start from an application generated by `mix phx.new` (Phoenix 1.8). For a `path:` dependency, deck.gl and the reasons behind each step, see"
              )
            } />
            <a
              id="install-readme"
              href={@readme_install_url}
              target="_blank"
              rel="noopener noreferrer"
              class="font-bold text-accent-ink underline-offset-2 hover:underline"
            >
              {gettext("the installation in the library's README")}<.icon
                name="hero-arrow-up-right-micro"
                class="ml-0.5 size-4"
              /></a>.
          </p>

          <ol class="mt-6 space-y-8">
            <.install_step
              id="install-step-dependency"
              number={1}
              title={gettext("Add the dependency to mix.exs")}
            >
              <.hex_release_note version={@version} hex={Catalogue.hex_release()} />
              <.code_block
                id="install-dependency"
                code={@snippets.dependency}
                language={:elixir}
                title="mix.exs"
              />
            </.install_step>

            <.install_step id="install-step-npm" number={2} title={gettext("Install MapLibre GL JS")}>
              <p class="mb-3 max-w-measure text-body text-ink-muted">
                {gettext(
                  "MaplibreX does not bundle MapLibre GL JS; your application owns its version. MaplibreX supports maplibre-gl 5 and 6, except deckgl_layer, which needs 5."
                )}
              </p>
              <.code_block id="install-npm" code={@snippets.npm} language={:shell} />
            </.install_step>

            <.install_step id="install-step-hooks" number={3} title={gettext("Register the hooks")}>
              <p class="mb-3 max-w-measure text-body text-ink-muted">
                <.rich_text text={
                  gettext(
                    "In `assets/js/app.js`, add the hooks to the ones the generated `LiveSocket` already has:"
                  )
                } />
              </p>
              <.code_block
                id="install-hooks"
                code={@snippets.hooks}
                language={:javascript}
                title="assets/js/app.js"
              />
              <p class="mt-4 mb-3 max-w-measure text-body text-ink-muted">
                <.rich_text text={
                  gettext(
                    "The bare `\"maplibrex\"` import resolves through `NODE_PATH`, which the generated esbuild profile points at `deps/`. The bundle found there imports `maplibre-gl`, which npm installed in `assets/node_modules`; add that directory to `NODE_PATH`:"
                  )
                } />
              </p>
              <.code_block
                id="install-esbuild"
                code={@snippets.esbuild}
                language={:elixir}
                title="config/config.exs"
              />
              <p class="mt-3 max-w-measure text-body text-ink-muted">
                <.rich_text text={
                  gettext(
                    "Without that entry the build stops with `Could not resolve \"maplibre-gl\"`. The `--external:@deck.gl/*` flag is only for an application without the deck.gl packages, which only `deckgl_layer` needs; with them installed, leave it out."
                  )
                } />
              </p>
            </.install_step>

            <.install_step
              id="install-step-worker"
              number={4}
              title={gettext("maplibre-gl 6 only: serve the worker")}
            >
              <p class="mb-3 max-w-measure text-body text-ink-muted">
                <.rich_text text={
                  gettext(
                    "maplibre-gl 6 starts its worker from separate files that esbuild does not copy into your build, and without them the map draws no tile data; maplibre-gl 5 needs none of this. Copy the files next to `app.js` with this function in `mix.exs`, and add `&copy_maplibre_worker/1` right after the esbuild task in the `assets.build` and `assets.deploy` aliases:"
                  )
                } />
              </p>
              <.code_block
                id="install-worker-copy"
                code={@snippets.worker_copy}
                language={:elixir}
                title="mix.exs"
              />
              <p class="mt-4 mb-3 max-w-measure text-body text-ink-muted">
                <.rich_text text={
                  gettext("Then point MapLibre at the copy, near the top of `assets/js/app.js`:")
                } />
              </p>
              <.code_block
                id="install-worker-url"
                code={@snippets.worker_url}
                language={:javascript}
                title="assets/js/app.js"
              />
              <p class="mt-3 max-w-measure text-body text-ink-muted">
                <.rich_text text={
                  gettext(
                    "Run `mix assets.build` after every install or upgrade of maplibre-gl: `mix phx.server` does not copy the files."
                  )
                } />
              </p>
            </.install_step>

            <.install_step
              id="install-step-css"
              number={5}
              title={gettext("Import the stylesheets")}
            >
              <.code_block
                id="install-css"
                code={@snippets.stylesheets}
                language={:css}
                title="assets/css/app.css"
              />
            </.install_step>

            <.install_step
              id="install-step-components"
              number={6}
              title={gettext("Import the components")}
            >
              <.code_block
                id="install-import"
                code={@snippets.import}
                language={:elixir}
                title="lib/my_app_web/live/map_live.ex"
              />
              <p class="mt-3 max-w-measure text-body text-ink-muted">
                <.rich_text text={
                  gettext(
                    "The components push their events whether or not your LiveView handles them, and an event with no matching clause crashes it: keep a catch-all as the last `handle_event/3`."
                  )
                } />
              </p>
            </.install_step>
          </ol>
        </section>

        <section id="minimal" class="mt-14" aria-labelledby="minimal-heading">
          <h2 id="minimal-heading" class="text-heading font-black">{gettext("A minimal map")}</h2>
          <p class="mt-2 max-w-measure text-body text-ink-muted">
            {gettext(
              "A map, a navigation control and one marker per city. When the visitor pans or zooms, map:moved updates the assigns."
            )}
          </p>
          <.code_block
            id="minimal-template"
            code={@snippets.minimal}
            language={:elixir}
            title="lib/my_app_web/live/map_live.ex"
            class="mt-4"
          />
        </section>

        <section id="families" class="mt-14" aria-labelledby="families-heading">
          <h2 id="families-heading" class="text-heading font-black">
            {gettext("Components by family")}
          </h2>
          <p class="mt-2 max-w-measure text-body text-ink-muted">
            <.link navigate={~p"/roadmap"} class="font-bold text-accent-ink hover:underline">
              {gettext("The roadmap")}
            </.link>
            {gettext("explains each status that is not stable, with its library issue.")}
          </p>

          <%!-- Below sm the three status columns give way to the same counts,
               as mark and number, under each family's name. --%>
          <div class="mt-5 overflow-x-auto rounded-panel border border-line">
            <table id="family-table" class="w-full text-left text-ui tabular-nums">
              <thead class="bg-surface text-label font-bold tracking-[0.06em] text-ink-subtle uppercase">
                <tr>
                  <th scope="col" class="px-4 py-2.5">{gettext("Family")}</th>
                  <th scope="col" class="px-4 py-2.5 text-right">{gettext("Components")}</th>
                  <th
                    :for={status <- [:stable, :limited, :planned]}
                    scope="col"
                    class="hidden px-4 py-2.5 sm:table-cell"
                  >
                    <span class="inline-flex items-center gap-1.5">
                      <.status_mark status={status} />{status_word(status)}
                    </span>
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-line">
                <tr :for={family <- @families} id={"family-row-#{family.id}"}>
                  <th scope="row" class="px-4 py-2.5 font-bold">
                    <.link
                      navigate={~p"/components" <> "#family-#{family.id}"}
                      class="text-ink underline-offset-2 hover:text-accent-ink hover:underline"
                    >
                      {family.label}
                    </.link>
                    <.status_summary id={"family-summary-#{family.id}"} counts={family.statuses} />
                  </th>
                  <td class="px-4 py-2.5 text-right align-top" data-count>{family.count}</td>
                  <td
                    :for={status <- [:stable, :limited, :planned]}
                    class={[
                      "hidden px-4 py-2.5 sm:table-cell",
                      family.statuses[status] == 0 && "text-ink-subtle"
                    ]}
                    data-status-count={status}
                  >
                    {family.statuses[status]}
                  </td>
                </tr>
              </tbody>
              <tfoot class="border-t border-line-strong font-bold">
                <tr id="family-row-total">
                  <th scope="row" class="px-4 py-2.5">
                    {gettext("All families")}
                    <.status_summary id="family-summary-total" counts={@totals} />
                  </th>
                  <td class="px-4 py-2.5 text-right align-top">{@total}</td>
                  <td
                    :for={status <- [:stable, :limited, :planned]}
                    class="hidden px-4 py-2.5 sm:table-cell"
                  >
                    {@totals[status]}
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
          <p
            id="family-legend"
            aria-hidden="true"
            class="mt-2.5 flex flex-wrap gap-x-4 gap-y-1 text-label text-ink-muted sm:hidden"
          >
            <span
              :for={status <- [:stable, :limited, :planned]}
              class="inline-flex items-center gap-1"
            >
              <.status_mark status={status} />{status_word(status)}
            </span>
          </p>
        </section>

        <section id="next" class="mt-14" aria-labelledby="next-heading">
          <h2 id="next-heading" class="text-heading font-black">{gettext("Where to go next")}</h2>
          <ul class="mt-4 max-w-measure divide-y divide-line border-y border-line">
            <.next_link
              navigate={~p"/components"}
              title={gettext("Components")}
              text={gettext("Every component by family, with its attributes, events and status.")}
            />
            <.next_link
              navigate={~p"/components/map"}
              title={gettext("The map example")}
              text={
                gettext(
                  "A map whose camera is driven from the server, with client-side commands and its events."
                )
              }
            />
            <.next_link
              navigate={~p"/scenarios"}
              title={gettext("Scenarios")}
              text={gettext("Several components combined into one working map.")}
            />
            <.next_link
              navigate={~p"/roadmap"}
              title={gettext("Roadmap")}
              text={gettext("What is limited or planned, and what the next library release fixes.")}
            />
          </ul>
        </section>
      </article>
    </Layouts.app>
    """
  end

  @doc """
  The line under the install step's dependency that says which release Hex
  has, given the `version` the demo runs and the `hex` release: while the
  library's `main` is ahead of Hex, that the release lacks the fixes the
  roadmap lists; otherwise, that `main` has nothing unreleased.
  """
  attr :version, :string, required: true
  attr :hex, :string, required: true

  def hex_release_note(assigns) do
    assigns = assign(assigns, :unreleased, Catalogue.unreleased?(assigns.version, assigns.hex))

    ~H"""
    <p
      id="install-hex-release"
      data-state={if(@unreleased, do: "unreleased", else: "released")}
      class="mb-3 max-w-measure text-body text-ink-muted"
    >
      <%= if @unreleased do %>
        {gettext(
          "The demo uses the library's main branch; MaplibreX %{hex}, the latest release on Hex, lacks the fixes listed on",
          hex: @hex
        )}
        <.link
          navigate={~p"/roadmap" <> "#next-release-heading"}
          class="font-bold text-accent-ink underline-offset-2 hover:underline"
        >
          {gettext("the roadmap")}</.link>.
      <% else %>
        {gettext(
          "The demo uses the library's main branch, which has nothing unreleased beyond MaplibreX %{hex}, the latest release on Hex.",
          hex: @hex
        )}
      <% end %>
    </p>
    """
  end

  # A family's status counts as mark and number, for the narrow table. The
  # word of each status is there for screen readers; the legend under the
  # table gives it to everyone else.
  attr :id, :string, required: true
  attr :counts, :map, required: true

  defp status_summary(assigns) do
    ~H"""
    <span id={@id} class="mt-1 flex flex-wrap gap-x-3.5 gap-y-1 font-normal sm:hidden">
      <span
        :for={status <- [:stable, :limited, :planned]}
        data-status-summary={status}
        class={["inline-flex items-center gap-1", @counts[status] == 0 && "text-ink-subtle"]}
      >
        <.status_mark status={status} />
        <span class="sr-only">{status_word(status)}</span>
        {@counts[status]}
      </span>
    </span>
    """
  end

  attr :id, :string, default: nil
  attr :number, :integer, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  defp install_step(assigns) do
    ~H"""
    <li id={@id} class="grid gap-x-4 gap-y-3 sm:grid-cols-[2rem_minmax(0,1fr)]">
      <span
        class="inline-flex size-7 items-center justify-center rounded-full border border-line-strong text-label font-bold text-ink-muted tabular-nums"
        aria-hidden="true"
      >
        {@number}
      </span>
      <div class="min-w-0">
        <h3 class="mb-3 text-body font-bold">{@title}</h3>
        {render_slot(@inner_block)}
      </div>
    </li>
    """
  end

  attr :navigate, :string, required: true
  attr :title, :string, required: true
  attr :text, :string, required: true

  defp next_link(assigns) do
    ~H"""
    <li>
      <.link
        navigate={@navigate}
        class="group flex items-center justify-between gap-4 py-3.5 hover:text-accent-ink"
      >
        <span>
          <span class="block font-bold">{@title}</span>
          <span class="block text-ui text-ink-muted">{@text}</span>
        </span>
        <.icon
          name="hero-arrow-right-micro"
          class="size-4 shrink-0 text-ink-subtle group-hover:text-accent-ink"
        />
      </.link>
    </li>
    """
  end
end
