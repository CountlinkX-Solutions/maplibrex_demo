defmodule MaplibrexDemoWeb.ComponentLive do
  @moduledoc """
  One component of the catalogue at `/components/:name`.

  The header gives the name, the status as mark and word, the summary and,
  for a limited or planned component, why, with its issues. Four tabs follow,
  each with a stable URL (`?tab=heex`, `?tab=events`, `?tab=attributes`; the
  preview has none):

    * Preview — the running example, or a plain "no example yet" state.
    * HEEx — the example's source, read at compile time.
    * Events — what the component sends to the LiveView, from the library's
      documentation.
    * Attributes — generated from the library's component metadata.

  Switching tabs is a patch. The preview panel stays in the page, hidden, so
  a running example keeps its map and its state.
  """
  use MaplibrexDemoWeb, :live_view

  alias MaplibrexDemoWeb.{Catalogue, LibraryDocs, NotFoundError}
  alias MaplibrexDemoWeb.Examples.Sources

  @tabs [:preview, :heex, :events, :attributes]

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
         |> assign(:attributes, LibraryDocs.attributes(component))
         |> assign(:events, LibraryDocs.events(component))
         |> assign(
           :sources,
           if(component.example, do: Sources.files(component.example), else: [])
         )
         |> assign(:payloads, %{})
         |> assign(:page_title, Atom.to_string(component.name))}

      :error ->
        raise NotFoundError, "no component is called #{inspect(name)}"
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :tab, parse_tab(params["tab"]))}
  end

  defp parse_tab(tab) do
    Enum.find(@tabs, :preview, &(Atom.to_string(&1) == tab))
  end

  # Sent by MaplibrexDemoWeb.Examples.Plumbing for every library event the
  # running example receives.
  @impl true
  def handle_info({:example_event, event, payload}, socket) do
    {:noreply, update(socket, :payloads, &Map.put(&1, event, payload))}
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
        id="component-tabs"
        aria-label={gettext("Component sections")}
        class="mt-7 flex gap-1 overflow-x-auto border-b border-line"
      >
        <.link
          :for={tab <- tabs()}
          id={"tab-#{tab}"}
          patch={tab_path(@component, tab)}
          aria-current={@tab == tab && "page"}
          class={[
            "-mb-px inline-flex shrink-0 items-center gap-1.5 border-b-2 px-3 py-2.5 text-ui font-bold sm:px-4",
            if(@tab == tab,
              do: "border-accent-ink text-accent-ink",
              else: "border-transparent text-ink-subtle hover:text-ink"
            )
          ]}
        >
          {tab_label(tab)}
          <span
            :if={count = tab_count(tab, assigns)}
            class="hidden rounded-inline bg-surface px-1.5 text-label text-ink-subtle tabular-nums sm:inline"
          >
            {count}
          </span>
        </.link>
      </nav>

      <section id="panel-preview" hidden={@tab != :preview} aria-labelledby="tab-preview">
        <%= if @component.example do %>
          <div class="overflow-hidden rounded-b-panel border border-t-0 border-line bg-canvas">
            {live_render(@socket, @component.example,
              id: "example-#{@component.name}-live",
              session: %{"locale" => @locale}
            )}
          </div>
          <.code_block
            :for={file <- @sources}
            :if={file.language == :heex}
            id="preview-source"
            code={file.source}
            html={file.html}
            language={:heex}
            title={file.path}
            collapse
            class="mt-4"
          />
        <% else %>
          <.example_coming component={@component} />
        <% end %>
      </section>

      <section :if={@tab == :heex} id="panel-heex" aria-labelledby="tab-heex" class="pt-6">
        <%= if @sources == [] do %>
          <.empty_panel id="source-empty" icon="hero-code-bracket">
            {gettext("This component has no example yet, so there is no source to show.")}
          </.empty_panel>
        <% else %>
          <p class="max-w-measure text-body text-ink-muted">
            {gettext(
              "The example's template and LiveView, read from the files that run in the preview."
            )}
          </p>
          <div class="mt-5 space-y-6">
            <.code_block
              :for={file <- @sources}
              id={"source-#{String.replace(file.name, ".", "-")}"}
              code={file.source}
              html={file.html}
              language={file.language}
              title={file.path}
            />
          </div>
        <% end %>
      </section>

      <section :if={@tab == :events} id="panel-events" aria-labelledby="tab-events" class="pt-6">
        <.events_panel events={@events} example?={@component.example != nil} payloads={@payloads} />
      </section>

      <section
        :if={@tab == :attributes}
        id="panel-attributes"
        aria-labelledby="tab-attributes"
        class="pt-6"
      >
        <.attributes_panel attributes={@attributes} />
      </section>

      <.pager
        id="component"
        label={gettext("Previous and next component")}
        previous={page_link(@previous)}
        next={page_link(@next)}
      />
    </Layouts.app>
    """
  end

  defp tabs, do: @tabs

  defp page_link(nil), do: nil
  defp page_link(component), do: %{name: component.name, path: ~p"/components/#{component.name}"}

  defp tab_path(component, :preview), do: ~p"/components/#{component.name}"
  defp tab_path(component, tab), do: ~p"/components/#{component.name}?#{[tab: tab]}"

  defp tab_label(:preview), do: gettext("Preview")
  defp tab_label(:heex), do: "HEEx"
  defp tab_label(:events), do: gettext("Events")
  defp tab_label(:attributes), do: gettext("Attributes")

  defp tab_count(:events, %{events: {:ok, events}}) when events != [], do: length(events)
  defp tab_count(:attributes, %{attributes: {:ok, %{attrs: attrs}}}), do: length(attrs)
  defp tab_count(_tab, _assigns), do: nil

  defp why_heading(:limited), do: gettext("Why it is limited")
  defp why_heading(:planned), do: gettext("Why it is planned")

  attr :component, :map, required: true

  defp example_coming(assigns) do
    ~H"""
    <div
      id="example-coming"
      data-status={@component.status}
      class="flex h-preview flex-col items-center justify-center rounded-b-panel border border-t-0 border-line bg-surface px-6 text-center"
    >
      <.icon name="hero-map" class="size-7 text-ink-subtle" />
      <p class="mt-3 font-bold">{gettext("No example yet")}</p>
      <p id="example-coming-note" class="mt-1 max-w-sm text-ui text-ink-muted">
        {cond do
          @component.status == :planned ->
            gettext(
              "This component cannot render yet, so it gets no example until its issue is fixed."
            )

          @component.example_note ->
            @component.example_note

          true ->
            gettext(
              "Its interactive example comes in a later update of the demo. Its events and attributes are already listed."
            )
        end}
      </p>
      <.link
        patch={tab_path(@component, :attributes)}
        class="mt-4 inline-flex items-center gap-1 text-ui font-bold text-accent-ink underline-offset-2 hover:underline"
      >
        {gettext("See its attributes")}
        <.icon name="hero-arrow-right-micro" class="size-4" />
      </.link>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :icon, :string, required: true
  slot :inner_block, required: true

  defp empty_panel(assigns) do
    ~H"""
    <div
      id={@id}
      class="flex max-w-measure items-start gap-3 rounded-panel border border-line bg-surface px-4 py-3.5 text-ui text-ink-muted"
    >
      <.icon name={@icon} class="mt-px size-5 shrink-0 text-ink-subtle" />
      <p>{render_slot(@inner_block)}</p>
    </div>
    """
  end

  attr :events, :any, required: true
  attr :example?, :boolean, default: false
  attr :payloads, :map, default: %{}

  defp events_panel(assigns) do
    ~H"""
    <%= case @events do %>
      <% :error -> %>
        <.empty_panel id="events-error" icon="hero-exclamation-circle">
          {gettext(
            "The library's documentation is not available in this build, so its events cannot be listed."
          )}
        </.empty_panel>
      <% {:ok, []} -> %>
        <.empty_panel id="events-empty" icon="hero-signal-slash">
          {gettext(
            "This component sends no events of its own. Bindings such as phx-click on its content work as usual."
          )}
        </.empty_panel>
      <% {:ok, events} -> %>
        <p class="max-w-measure text-body text-ink-muted">
          {gettext(
            "The events this component sends to the LiveView, as the library documents them. Each arrives in handle_event/3."
          )}
          <span :if={@example?}>
            {gettext(
              "Use the preview; the last payload of each event the example receives appears here."
            )}
          </span>
        </p>
        <ul class="mt-5 divide-y divide-line border-y border-line">
          <li :for={event <- events} id={"event-#{event_slug(event.name)}"} class="py-3.5">
            <p class="font-mono text-ui font-semibold">{event.name}</p>
            <p class="mt-0.5 text-ui text-ink-muted"><.rich_text text={event.doc} /></p>
            <%= if @example? do %>
              <%= case Map.fetch(@payloads, event.name) do %>
                <% {:ok, payload} -> %>
                  <.code_block
                    id={"payload-#{event_slug(event.name)}"}
                    code={inspect(payload, pretty: true, limit: :infinity)}
                    language={:elixir}
                    title={gettext("Last payload received")}
                    class="mt-2.5 max-w-measure"
                  />
                <% :error -> %>
                  <p
                    id={"payload-#{event_slug(event.name)}-waiting"}
                    class="mt-1.5 inline-flex items-center gap-1.5 text-label text-ink-subtle"
                  >
                    <.icon name="hero-clock-micro" class="size-3.5" />
                    {gettext("Not received yet.")}
                  </p>
              <% end %>
            <% end %>
          </li>
        </ul>
    <% end %>
    """
  end

  @doc false
  def event_slug(name), do: String.replace(name, ":", "-")

  attr :attributes, :any, required: true

  defp attributes_panel(assigns) do
    ~H"""
    <%= case @attributes do %>
      <% :error -> %>
        <.empty_panel id="attributes-error" icon="hero-exclamation-circle">
          {gettext("The library does not describe this component's attributes.")}
        </.empty_panel>
      <% {:ok, %{attrs: attrs, slots: slots}} -> %>
        <p class="max-w-measure text-body text-ink-muted">
          {gettext(
            "Generated from the component's definition in the library, so it always matches the version this demo runs."
          )}
        </p>
        <div class="mt-5 overflow-x-auto rounded-panel border border-line">
          <table id="attributes-table" class="w-full min-w-[42rem] text-left text-ui">
            <thead class="bg-surface text-label font-bold tracking-caps text-ink-subtle uppercase">
              <tr>
                <th scope="col" class="px-4 py-2.5">{gettext("Attribute")}</th>
                <th scope="col" class="px-4 py-2.5">{gettext("Type")}</th>
                <th scope="col" class="px-4 py-2.5">{gettext("Default")}</th>
                <th scope="col" class="px-4 py-2.5">{gettext("Description")}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-line">
              <tr :for={attr <- attrs} id={"attr-#{attr.name}"} class="align-top">
                <th scope="row" class="px-4 py-3 font-normal whitespace-nowrap">
                  <span class="font-mono font-semibold">{attr_name(attr)}</span>
                  <span
                    :if={attr.required}
                    data-required
                    class="ml-1.5 rounded-inline bg-accent-soft px-1.5 py-px text-label font-bold text-accent-ink"
                  >
                    {gettext("required")}
                  </span>
                </th>
                <td class="px-4 py-3 font-mono text-ink-muted">{attr.type}</td>
                <td class="px-4 py-3">
                  <%= case attr.default do %>
                    <% {:value, value} -> %>
                      <code data-default class="inline-code whitespace-nowrap">{inspect(value)}</code>
                    <% :none -> %>
                      <span class="text-ink-subtle" aria-label={gettext("none")}>—</span>
                  <% end %>
                </td>
                <td class="px-4 py-3 text-ink-muted">
                  <.rich_text :if={attr.doc} text={attr.doc} />
                  <span :if={attr.type == "global"}>
                    {gettext("Any other HTML attribute, passed on to the component's element.")}
                  </span>
                  <span :if={!attr.doc and attr.type != "global"} class="text-ink-subtle">
                    {gettext("Not documented by the library.")}
                  </span>
                  <span :if={list_values?(attr)} class="mt-1 block">
                    {gettext("One of")}
                    <span :for={value <- attr.values} class="mr-1 inline-block">
                      <code class="inline-code">{inspect(value)}</code>
                    </span>
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <%= if slots != [] do %>
          <h3 class="mt-8 text-body font-bold">{gettext("Slots")}</h3>
          <ul class="mt-2 divide-y divide-line border-y border-line text-ui">
            <li :for={slot <- slots} id={"slot-#{slot.name}"} class="flex flex-wrap gap-x-3 py-2.5">
              <span class="font-mono font-semibold">{slot.name}</span>
              <span class="text-ink-muted">
                {cond do
                  slot.doc -> slot.doc
                  slot.required -> gettext("Required.")
                  true -> gettext("Optional.")
                end}
              </span>
            </li>
          </ul>
        <% end %>
    <% end %>
    """
  end

  # The allowed values, unless the library's description already lists them.
  defp list_values?(%{values: [first | _], doc: doc}),
    do: not String.contains?(doc || "", inspect(first))

  defp list_values?(_attr), do: false

  defp attr_name(%{type: "global"}), do: gettext("global attributes")
  defp attr_name(%{name: name}), do: Atom.to_string(name)
end
