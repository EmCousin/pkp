// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"

import * as ActionCable from '@rails/actioncable'
window.Cable = ActionCable.createConsumer()

import * as ActiveStorage from '@rails/activestorage'
ActiveStorage.start()

import "tail.select.js/js/tail.select-full"

import "./controllers"

document.addEventListener("DOMContentLoaded", function() {
  $('[data-toggle="tooltip"]').tooltip()
  $('[data-toggle="dropdown"]').dropdown()
})

