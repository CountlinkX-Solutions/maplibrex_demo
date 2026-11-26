// Light, dark or the system's choice.
//
// The server renders `data-theme` on <html> from the `theme` cookie
// (MaplibrexDemoWeb.Plugs.SetTheme), so an explicit choice is applied before
// the first paint without an inline script. With no cookie, app.css follows
// `prefers-color-scheme`.
//
// A switch is any element with `data-theme-choice="system|light|dark"` that
// dispatches `app:set-theme`, e.g. `phx-click={JS.dispatch("app:set-theme")}`.
// Its pressed look comes from CSS on <html data-theme>; this module keeps
// `aria-pressed` in step for assistive technology.
//
// The examples' basemaps follow the theme in effect, which the server learns
// from `effectiveTheme()`: in the LiveSocket's params when an example
// connects, and from the `ExampleTheme` hook when it changes afterwards
// (MaplibrexDemoWeb.Examples.Plumbing).

const EXPLICIT = ["light", "dark"]
const ONE_YEAR = 60 * 60 * 24 * 365
const darkScheme = window.matchMedia("(prefers-color-scheme: dark)")

const currentTheme = () => document.documentElement.getAttribute("data-theme") || "system"

// "light" or "dark": the explicit choice, or else the system's.
export const effectiveTheme = () => {
  const theme = currentTheme()
  if (EXPLICIT.includes(theme)) return theme
  return darkScheme.matches ? "dark" : "light"
}

const announce = () => window.dispatchEvent(new CustomEvent("app:theme-changed"))

const syncSwitches = () => {
  const theme = currentTheme()

  document.querySelectorAll("[data-theme-choice]").forEach(button => {
    button.setAttribute("aria-pressed", String(button.dataset.themeChoice === theme))
  })
}

const applyTheme = theme => {
  const root = document.documentElement

  if (EXPLICIT.includes(theme)) {
    root.setAttribute("data-theme", theme)
    document.cookie = `theme=${theme}; path=/; max-age=${ONE_YEAR}; samesite=lax`
  } else {
    root.removeAttribute("data-theme")
    document.cookie = "theme=; path=/; max-age=0; samesite=lax"
  }

  syncSwitches()
  announce()
}

export const initTheme = () => {
  window.addEventListener("app:set-theme", event => applyTheme(event.target.dataset.themeChoice))
  // Live navigation renders fresh switches; mark the pressed one again.
  window.addEventListener("phx:page-loading-stop", syncSwitches)
  // With no explicit choice, the system's scheme can change under the page.
  darkScheme.addEventListener("change", () => {
    if (currentTheme() === "system") announce()
  })
  syncSwitches()
}

// On an element inside an example's LiveView: sends it the theme in effect
// as a "theme" event when the element mounts and whenever the theme changes.
// The reply callback keeps a push made while disconnected from raising; the
// LiveView reads the theme again from the params when it rejoins.
export const ExampleTheme = {
  mounted() {
    this.report = () => this.pushEvent("theme", {theme: effectiveTheme()}, () => {})
    window.addEventListener("app:theme-changed", this.report)
    this.report()
  },
  destroyed() {
    window.removeEventListener("app:theme-changed", this.report)
  }
}
