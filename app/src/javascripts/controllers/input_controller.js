import { Controller } from "stimulus"

export default class InputController extends Controller {
  prevent(event) {
    event.preventDefault();
  }
}
