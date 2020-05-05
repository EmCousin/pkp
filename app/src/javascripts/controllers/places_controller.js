import { Controller } from "stimulus"
import places from 'places.js';

export default class PlacesController extends Controller {
  static targets = ["form", "address", "zipCode", "city", "country"]

  connect() {
    const placesAutocomplete = places({
      appId: this.data.get('app_id'),
      apiKey: this.data.get('api_key'),
      container: this.addressTarget,
      type: 'address',
      templates: {
        value: ({name}) => name,
        suggestion: ({name, postcode, city, country}) => `${name}, ${postcode} ${city}, ${country}`,
        footer: null,
      },
      userHasOptedOut: true,
      debounce: 200,
    });

    let controller = this;

    placesAutocomplete.on('change', ({suggestion}) => {
      if (suggestion) {
        controller.addressTarget.value = suggestion.name;
        controller.zipCodeTarget.value = suggestion.postcode;
        controller.cityTarget.value = suggestion.city;
        controller.countryTarget.value = suggestion.country;
      }
    });

    placesAutocomplete.on('clear', () => {
      controller.addressTarget.value = '';
      controller.zipCodeTarget.value = '';
      controller.cityTarget.value = '';
      controller.countryTarget.value = '';
    });
  }
}
