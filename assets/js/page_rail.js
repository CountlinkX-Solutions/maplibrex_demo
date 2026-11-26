// The "On this page" rail beside the overview and the roadmap
// (`page_rail` in layouts.ex). Its links are plain anchors, so they work
// without this hook; the hook marks, with aria-current, the section being
// read: the last one whose heading has reached the top of the page, the
// first one while the reader is above it but can see it, and the last one at
// the very end of the page. The rail has phx-update="ignore", so LiveView
// patches keep the mark.
export const PageRail = {
  mounted() {
    this.items = [...this.el.querySelectorAll("a[href^='#']")]
      .map(link => ({link, target: document.getElementById(decodeURIComponent(link.hash.slice(1)))}))
      .filter(item => item.target)

    // A click marks its own link until the jump it causes has settled, even
    // when the page cannot scroll that heading all the way up.
    this.onClick = event => {
      const item = this.items.find(({link}) => link === event.target.closest("a"))
      if (!item) return
      this.mark(item)
      this.hold(250)
    }

    this.onScroll = () => {
      if (this.held) return this.hold(150)
      if (this.frame) return
      this.frame = requestAnimationFrame(() => {
        this.frame = null
        this.mark(this.current())
      })
    }

    this.el.addEventListener("click", this.onClick)
    window.addEventListener("scroll", this.onScroll, {passive: true})
    window.addEventListener("resize", this.onScroll, {passive: true})
    this.mark(this.current())
  },

  destroyed() {
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onScroll)
    cancelAnimationFrame(this.frame)
    clearTimeout(this.release)
  },

  hold(ms) {
    this.held = true
    clearTimeout(this.release)
    this.release = setTimeout(() => (this.held = false), ms)
  },

  current() {
    if (this.items.length === 0) return null

    const page = document.documentElement
    const scrollable = page.scrollHeight > window.innerHeight
    if (scrollable && window.scrollY + window.innerHeight >= page.scrollHeight - 2) {
      return this.items[this.items.length - 1]
    }

    let current = null
    for (const item of this.items) {
      const line = (parseFloat(getComputedStyle(item.target).scrollMarginTop) || 0) + 16
      if (item.target.getBoundingClientRect().top <= line) current = item
    }

    const first = this.items[0]
    if (!current && first.target.getBoundingClientRect().top < window.innerHeight) current = first
    return current
  },

  mark(current) {
    for (const item of this.items) {
      if (item === current) item.link.setAttribute("aria-current", "true")
      else item.link.removeAttribute("aria-current")
    }
  }
}
