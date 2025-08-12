import { Controller } from "@hotwired/stimulus"
import { loadStripe } from '@stripe/stripe-js'

export default class StripeController extends Controller {
  static targets = ["form", "cardElement", "cardErrors"]
  static values = {
    key: String,
    locale: { type: String, default: 'fr' },
    paymentIntentClientSecret: String,
    returnUrl: String
  }

  async connect() {
    this.stripe = await loadStripe(this.keyValue, { locale: this.localeValue })
    this.mountPaymentElement()
  }

  mountPaymentElement() {
    const appearance = { theme: 'stripe' }
    const clientSecret = this.paymentIntentClientSecretValue
    this.elements = this.stripe.elements({ appearance, clientSecret })
    const paymentElementOptions = { layout: "accordion" }
    const paymentElement = this.elements.create('payment', paymentElementOptions)
    paymentElement.mount(this.cardElementTarget)

    paymentElement.on('change', (event) => {
      this.displayError(event?.error?.message || '')
    })

    return paymentElement
  }

  async confirmPayment(event) {
    event.preventDefault()

    const {error} = await this.stripe.confirmPayment({
      elements: this.elements,
      confirmParams: {
        return_url: `${window.location.origin}/${this.returnUrlValue}`,
      },
    })

    if (error.type === "card_error" || error.type === "validation_error") {
      this.displayError(error.message);
    } else {
      this.displayError("An unexpected error occurred.");
    }
  }

  displayError(errorMessage) {
    this.cardErrorsTarget.textContent = errorMessage
  }
}
