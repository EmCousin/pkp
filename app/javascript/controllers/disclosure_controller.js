import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "collapsedLabel", "expandedLabel", "icon"]

  toggle(event) {
    const expanded = event.currentTarget.getAttribute("aria-expanded") !== "true"

    event.currentTarget.setAttribute("aria-expanded", String(expanded))
    this.contentTarget.hidden = !expanded
    this.collapsedLabelTarget.hidden = expanded
    this.expandedLabelTarget.hidden = !expanded
    this.iconTarget.classList.toggle("rotate-180", expanded)
  }
}
