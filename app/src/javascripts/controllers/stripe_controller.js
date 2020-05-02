import { Controller } from "stimulus"
import {loadStripe} from '@stripe/stripe-js';

export default class StripeController extends Controller {
  static targets = ["form", "cardElement", "cardErrors"]

  async connect() {
    const stripe = await loadStripe(this.data.get('key'));
    const elements = stripe.elements();

    var style = {
      base: {
        color: '#303238',
        fontSize: '16px',
        fontFamily: '"Open Sans", sans-serif',
        fontSmoothing: 'antialiased',
        '::placeholder': {
          color: '#CFD7DF',
        },
      },
      invalid: {
        color: '#e5424d',
        ':focus': {
          color: '#303238',
        },
      },
    };

    const card = elements.create('card', {style});
    card.mount(this.cardElementTarget);

    // Handle real-time validation errors from the card Element.
    let controller = this;
    card.addEventListener('change', function (event) {
      let displayError = controller.cardErrorsTarget;
      if (event.error) {
        displayError.textContent = event.error.message;
      } else {
        displayError.textContent = '';
      }
    });

    // Handle form submission.
    let form = controller.formTarget;
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      let {error, token} = await stripe.createToken(card);
      if (error) {
        // Inform the user if there was an error.
        var errorElement = this.cardErrorsTarget;
        errorElement.textContent = error.message;
      } else {
        // Send the token to your server.
        controller.stripeTokenHandler(token);
      }
    });
  }

  // Submit the form with the token ID.
  stripeTokenHandler(token) {
    // Insert the token ID into the form so it gets submitted to the server
    const form = this.formTarget;
    let hiddenInput = document.createElement('input');
    hiddenInput.setAttribute('type', 'hidden');
    hiddenInput.setAttribute('name', 'stripeToken');
    hiddenInput.setAttribute('value', token.id);
    form.appendChild(hiddenInput);

    // Submit the form
    form.submit();
  }
}
