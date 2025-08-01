import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static classes = ["output"]

  preview() {
    if (this.uploadedFile) {
      const reader = new FileReader()
      reader.onload = () => {
        if (this.outputTarget.nodeName === "IMG") {
          this.outputTarget.src = reader.result
        } else {
          const img = document.createElement("img")
          img.src = reader.result
          console.log(this.outputClasses, 'coucou')
          img.classList.add(...this.outputClasses)
          this.outputTarget.replaceWith(img)
        }
      }
      reader.readAsDataURL(this.uploadedFile)
    }
  }

  get uploadedFile() {
    return this.inputTarget.files && this.inputTarget.files[0]
  }
}
