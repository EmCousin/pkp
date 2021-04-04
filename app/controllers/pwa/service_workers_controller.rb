# frozen_string_literal: true

module Pwa
  class ServiceWorkersController < ApplicationController
    layout false
    protect_from_forgery except: :show

    def show
      respond_to(&:js)
    end
  end
end
