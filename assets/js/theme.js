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

const EXPLICIT = ["light", "dark"]
const ONE_YEAR = 60 * 60 * 24 * 365

const currentTheme = () => document.documentElement.getAttribute("data-theme") || "system"

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
}

export const initTheme = () => {
  window.addEventListener("app:set-theme", event => applyTheme(event.target.dataset.themeChoice))
  // Live navigation renders fresh switches; mark the pressed one again.
  window.addEventListener("phx:page-loading-stop", syncSwitches)
  syncSwitches()
}
