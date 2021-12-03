import { Controller } from "@hotwired/stimulus"

export default class InputController extends Controller {
  prevent(event) {
    event.preventDefault();
  }
}
