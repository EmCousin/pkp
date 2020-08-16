import { Controller } from "stimulus"
import {loadStripe} from '@stripe/stripe-js';

export default class StripeController extends Controller {
  static targets = ["form", "cardElement", "cardErrors"]

  async connect() {
    const stripe = await loadStripe(this.data.get('key'));
    const card = this.mountCard(stripe);

    this.sendTokenToServerOnSubmit(stripe, card);
  }

  mountCard(stripe) {
    const style = {
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

    const card = stripe.elements().create('card', {style});
    card.mount(this.cardElementTarget);
    card.addEventListener('change', (event) => {
      this.displayError(event?.error?.message || '');
    });

    return card;
  }

  sendTokenToServerOnSubmit(stripe, card) {
    let form = this.formTarget;
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      let {error, token} = await stripe.createToken(card);
      if (error) {
        this.displayError(error.message);
      } else {
        this.insertTokenIntoFormAndSubmit(token);
      }
    });
  }

  displayError(errorMessage) {
    this.cardErrorsTarget.textContent = errorMessage;
  }

  insertTokenIntoFormAndSubmit(token) {
    const form = this.formTarget;
    let hiddenInput = document.createElement('input');
    hiddenInput.setAttribute('type', 'hidden');
    hiddenInput.setAttribute('name', 'stripeToken');
    hiddenInput.setAttribute('value', token.id);
    form.appendChild(hiddenInput);
    form.submit();
  }
}
