// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import {MapHooks} from "maplibrex"
import {initTheme} from "./theme"
import {initShell} from "./shell"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: MapHooks
})

// Show progress bar on live navigation and form submits, in the accent colour.
topbar.config({barColors: {0: "#5b3fa6"}, shadowColor: "rgba(0, 0, 0, .2)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// No custom map glue is needed here: MaplibreX registers its own LiveView
// handlers, so `push_event(socket, "map:fly_to", %{...})` from a LiveView
// reaches the map directly.

initTheme()
initShell()

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
