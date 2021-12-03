import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['submit']

  connect() {
    if (this.hasSubmitTarget) {
      const submitTargetValue = this.submitTarget.value

      this.element.addEventListener(
        'turbo:submit-start',
        () => {
          this.submitTarget.disabled = true
          this.submitTarget.classList.add('disabled')
          if (this.submitTarget.dataset.disableWith) {
            this.submitTarget.value = this.submitTarget.dataset.disableWith
          }
        }
      )

      this.element.addEventListener(
        'turbo:submit-end',
        () => {
          this.submitTarget.disabled = false
          this.submitTarget.classList.remove('disabled')
          this.submitTarget.value = submitTargetValue
        }
      )
    }
  }
}
