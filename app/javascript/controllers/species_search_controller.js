import { Controller } from "@hotwired/stimulus"

// Search-as-you-type for the tank page's "add a species" form. Typing asks
// /search_species for matches; picking one fills the hidden species_id field
// and enables the Add button.
export default class extends Controller {
  static targets = ["input", "results", "speciesId", "submit"]
  static values = { url: String, water: String, strict: Boolean }

  connect() {
    this.clearChoice()
  }

  search() {
    this.clearChoice()
    clearTimeout(this.timer)
    const term = this.inputTarget.value.trim()
    if (term.length < 2) return this.hideResults()
    // wait for a pause in typing rather than searching on every keystroke
    this.timer = setTimeout(() => this.fetchResults(term), 200)
  }

  async fetchResults(term) {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("term", term)
    url.searchParams.set("water", this.waterValue)
    if (this.strictValue) url.searchParams.set("strict", "1")
    const response = await fetch(url, { headers: { Accept: "application/json" } })
    const results = await response.json()
    // ignore answers to an older search that arrive after a newer one started
    if (term === this.inputTarget.value.trim()) this.showResults(results)
  }

  showResults(results) {
    const items = results.length ? results.map((result) => this.resultButton(result)) : [this.noMatches()]
    this.resultsTarget.replaceChildren(...items)
    this.resultsTarget.hidden = false
  }

  // textContent (not innerHTML) so a name can never inject markup
  resultButton(result) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "block w-full text-left px-3 py-2 hover:bg-teal-100 focus:bg-teal-100 dark:hover:bg-teal-800 dark:focus:bg-teal-800"

    const name = document.createElement("span")
    name.className = "font-medium"
    name.textContent = result.text

    const details = document.createElement("span")
    details.className = result.suits_water
      ? "block text-xs text-gray-500 dark:text-neutral-400"
      : "block text-xs text-amber-600 dark:text-amber-400"
    const otherName = result.other_name ? `${result.other_name} · ` : ""
    details.textContent = otherName + result.kind + (result.suits_water ? "" : " ⚠ doesn't match this tank's water")

    button.append(name, details)
    button.addEventListener("click", () => this.choose(result))
    return button
  }

  noMatches() {
    const message = document.createElement("p")
    message.className = "px-3 py-2 text-sm text-gray-500 dark:text-neutral-400"
    message.textContent = "No matches"
    return message
  }

  choose(result) {
    this.speciesIdTarget.value = result.id
    this.inputTarget.value = result.text
    this.submitTarget.disabled = false
    this.hideResults()
  }

  // Enter picks the first match instead of submitting the form with nothing chosen
  keydown(event) {
    if (event.key === "Escape") return this.hideResults()
    if (event.key !== "Enter" || this.speciesIdTarget.value) return
    event.preventDefault()
    this.resultsTarget.querySelector("button")?.click()
  }

  // close the list when clicking anywhere outside the form
  close(event) {
    if (!this.element.contains(event.target)) this.hideResults()
  }

  clearChoice() {
    this.speciesIdTarget.value = ""
    this.submitTarget.disabled = true
  }

  hideResults() {
    this.resultsTarget.hidden = true
  }
}
