// Browser-only behaviour of the catalogue shell. Templates trigger these with
// `JS.dispatch/2`, so no hook or inline script is needed.

// <dialog> drawers. `showModal()` gives focus trapping, Escape to close and an
// inert page behind it. The template marks the dialog with
// `JS.ignore_attributes(["open"])`, so LiveView patches keep it open.
const initDialogs = () => {
  window.addEventListener("app:dialog-open", event => {
    const dialog = event.target
    if (dialog instanceof HTMLDialogElement && !dialog.open) dialog.showModal()
  })

  window.addEventListener("app:dialog-close", event => {
    const dialog = event.target
    if (dialog instanceof HTMLDialogElement) dialog.close()
  })

  // A click on the backdrop lands on the <dialog> element itself.
  document.addEventListener("click", event => {
    const target = event.target
    if (target instanceof HTMLDialogElement && "closeOnBackdrop" in target.dataset) target.close()
  })
}

// Copy buttons: `data-copy-target` names the element whose text is copied.
// `data-copied` drives the "Copied" label for two seconds.
const initCopy = () => {
  window.addEventListener("app:copy", event => {
    const button = event.target
    const source = document.getElementById(button.dataset.copyTarget)
    if (!source || !navigator.clipboard) return

    navigator.clipboard.writeText(source.textContent).then(() => {
      button.dataset.copied = ""
      clearTimeout(button.copiedTimer)
      button.copiedTimer = setTimeout(() => delete button.dataset.copied, 2000)
    })
  })
}

// Long sources open and close with `JS.toggle_attribute/2` in the template,
// which LiveView keeps across patches. This only keeps the button in place
// when "Show less" shortens a source the reader has scrolled through, so the
// page does not leave them far below it. The event arrives before the toggle.
const initCodeToggle = () => {
  window.addEventListener("app:code-toggle", event => {
    const button = event.target
    if (button.getAttribute("aria-expanded") !== "true") return

    const before = button.getBoundingClientRect().top
    requestAnimationFrame(() => {
      const shift = button.getBoundingClientRect().top - before
      if (shift !== 0) window.scrollBy(0, shift)
    })
  })
}

// "/" focuses the component filter, as on most documentation sites, unless
// the visitor is already typing somewhere.
const initSearchShortcut = () => {
  document.addEventListener("keydown", event => {
    if (event.key !== "/" || event.metaKey || event.ctrlKey || event.altKey) return

    const target = event.target
    if (target.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName)) return

    const input = document.getElementById("component-filter-input")
    if (input && input.offsetParent !== null) {
      event.preventDefault()
      input.focus()
      input.select()
    }
  })
}

export const initShell = () => {
  initDialogs()
  initCopy()
  initCodeToggle()
  initSearchShortcut()
}
