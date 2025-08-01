import { Controller } from "@hotwired/stimulus"
import tail from '../inits/tail.select.min.js'

export default class SelectController extends Controller {
  static values = {
    locale: String
  }

  connect() {
    tail.select('#' + this.element.id, {
      search: true,
      multiSelectAll: true,
      deselect: true,
      locale: this.hasLocaleValue ? this.localeValue : 'fr'
    })
  }
}
