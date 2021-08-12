import { Controller } from "stimulus"

export default class extends Controller {
  static values = {
    message: String
  }

  connect() {
    this.form.addEventListener(
      'submit',
      (event) => {
        this.confirm(event, () => event.currentTarget.submit(event))
      }
    )
  }

  confirm(event, callback) {
    event.preventDefault()
    event.stopPropagation()

    if (window.confirm(this.messageValue)) {
      callback()
    } else {
      return false
    }
  }

  get form() {
    return this.element.form || this.element
  }
}
