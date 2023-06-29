// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import ConfirmController from "./confirm_controller"
application.register("confirm", ConfirmController)

import FormController from "./form_controller"
application.register("form", FormController)

import InputController from "./input_controller"
application.register("input", InputController)

import PlacesController from "./places_controller"
application.register("places", PlacesController)

import PwaController from "./pwa_controller"
application.register("pwa", PwaController)

import SelectController from "./select_controller"
application.register("select", SelectController)

import ServiceWorkerController from "./service_worker_controller"
application.register("service-worker", ServiceWorkerController)

import StripeController from "./stripe_controller"
application.register("stripe", StripeController)
