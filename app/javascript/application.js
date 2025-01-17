// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"

import * as ActionCable from '@rails/actioncable'
window.Cable = ActionCable.createConsumer()

import * as ActiveStorage from '@rails/activestorage'
ActiveStorage.start()

import "./controllers"
