import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "toggle", "form", "input", "status", "results", "result", "recents", "recentList"]
  static values = { context: String }

  connect() {
    this.sequence = 0
    this.selected = -1
  }

  disconnect() {
    clearTimeout(this.timer)
    this.request?.abort()
  }

  open(event) {
    event?.preventDefault()
    this.dialogTarget.showModal()
    this.toggleTarget.setAttribute("aria-expanded", "true")
    this.inputTarget.focus()
    this.inputTarget.select()
    this.search()
  }

  close() {
    clearTimeout(this.timer)
    this.request?.abort()
    this.dialogTarget.close()
  }

  closed() {
    this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  shortcut(event) {
    if ((event.metaKey || event.ctrlKey) && !event.altKey && event.key.toLowerCase() === "k") {
      event.preventDefault()
      this.dialogTarget.open ? this.close() : this.open()
    }
  }

  search() {
    clearTimeout(this.timer)
    this.request?.abort()
    const sequence = ++this.sequence
    const query = this.inputTarget.value.trim().slice(0, 80)
    this.resultsTarget.replaceChildren()
    this.inputTarget.removeAttribute("aria-activedescendant")
    this.selected = -1
    this.recentsTarget.hidden = query.length > 0
    if (query.length < 2) {
      this.statusTarget.textContent = "Enter at least 2 characters."
      if (!query) this.showRecents()
      return
    }
    this.statusTarget.textContent = "Searching…"
    this.timer = setTimeout(() => this.load(query, sequence), 180)
  }

  async load(query, sequence) {
    this.request = new AbortController()
    const url = new URL(this.formTarget.action)
    url.search = new URLSearchParams(new FormData(this.formTarget)).toString()
    url.searchParams.set("q", query)
    try {
      const response = await fetch(url, { signal: this.request.signal, headers: { "X-Requested-With": "XMLHttpRequest", Accept: "text/html" } })
      if (!response.ok) throw new Error("Search failed")
      if (response.redirected) { window.location.assign(response.url); return }
      const html = await response.text()
      if (sequence !== this.sequence || !this.dialogTarget.open) return
      this.resultsTarget.innerHTML = html
      const count = this.resultTargets.length
      this.statusTarget.textContent = `${count} ${count === 1 ? "result" : "results"}`
    } catch (error) {
      if (error.name !== "AbortError" && sequence === this.sequence) {
        this.statusTarget.textContent = "Search is unavailable. Try again."
      }
    }
  }

  navigate(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      event.stopPropagation()
      this.close()
    } else if (["ArrowDown", "ArrowUp"].includes(event.key) && this.resultTargets.length) {
      event.preventDefault()
      const count = this.resultTargets.length
      this.selected = this.selected < 0 ? (event.key === "ArrowDown" ? 0 : count - 1) :
        (this.selected + (event.key === "ArrowDown" ? 1 : -1) + count) % count
      this.resultTargets.forEach((result, index) => result.setAttribute("aria-selected", index === this.selected ? "true" : "false"))
      const selected = this.resultTargets[this.selected]
      this.inputTarget.setAttribute("aria-activedescendant", selected.id)
      selected.scrollIntoView({ block: "nearest" })
    } else if (event.key === "Enter" && this.selected >= 0) {
      event.preventDefault()
      this.resultTargets[this.selected].click()
    }
  }

  choose() {
    this.remember()
    this.close()
  }

  submit() {
    this.remember()
  }

  remember() {
    const query = this.inputTarget.value.trim().slice(0, 80)
    if (query.length < 2) return
    const recent = [query, ...this.recentQueries().filter(value => value.toLowerCase() !== query.toLowerCase())].slice(0, 5)
    try { localStorage.setItem(this.storageKey, JSON.stringify(recent)) } catch { /* Storage can be disabled by browser policy. */ }
  }

  recentQueries() {
    try {
      const recent = JSON.parse(localStorage.getItem(this.storageKey) || "[]")
      return Array.isArray(recent) ? recent.filter(value => typeof value === "string" && value.length >= 2 && value.length <= 80).slice(0, 5) : []
    } catch { return [] }
  }

  showRecents() {
    this.recentListTarget.replaceChildren()
    const queries = this.recentQueries()
    this.recentsTarget.hidden = queries.length === 0
    queries.forEach(query => {
      const button = document.createElement("button")
      button.type = "button"
      button.textContent = query
      button.addEventListener("click", () => {
        this.inputTarget.value = query
        this.inputTarget.focus()
        this.search()
      })
      this.recentListTarget.append(button)
    })
  }

  clearRecents() {
    try { localStorage.removeItem(this.storageKey) } catch { /* Storage can be disabled by browser policy. */ }
    this.showRecents()
  }

  get storageKey() {
    return `athleteace:search:${this.contextValue}`
  }
}
