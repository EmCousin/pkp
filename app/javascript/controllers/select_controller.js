import { Controller } from "@hotwired/stimulus"
import select from "tail.select.js/js/tail.select-full"

export default class SelectController extends Controller {
  static values = {
    locale: String
  }

  connect() {
    select(this.element, {
      search: true,
      multiSelectAll: true,
      deselect: true,
      locale: this.hasLocaleValue ? this.localeValue : 'fr'
    })
  }
}
