// Entry point for the build script in your package.json
import "./src/jquery"
import "./src/jquery-ui"
import "bootstrap"
import "@hotwired/turbo-rails"

import * as ActionCable from '@rails/actioncable'
window.Cable = ActionCable.createConsumer()

import * as ActiveStorage from '@rails/activestorage'
ActiveStorage.start()

import "tail.select.js/js/tail.select-full"

// import 'places.js'

import "./controllers"

document.addEventListener("DOMContentLoaded", function() {
  $('[data-toggle="tooltip"]').tooltip()
  $('[data-toggle="dropdown"]').dropdown()
})

