import { Controller } from "stimulus"

export default class MemberController extends Controller {
  // static targets = ["form", "cardElement", "cardErrors"]

  connect() {
    const members = this.data.get('collection');
    window.data = this.data;
    console.log('MEMBERS', members, this.data);
  }

  select() {
    return false;
  }
}
