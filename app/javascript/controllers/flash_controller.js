import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss(event) {
    const button = event.currentTarget
    const dismissButtons = Array.from(document.querySelectorAll("button[data-flash-dismiss]"))
    const index = dismissButtons.indexOf(button)
    const fallback = dismissButtons[index + 1] || dismissButtons[index - 1] || document.getElementById("main-content")
    const restoreFocus = document.activeElement === button

    this.element.remove()
    if (restoreFocus) fallback?.focus()
  }
}
