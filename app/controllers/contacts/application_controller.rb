# frozen_string_literal: true

module Contacts
  class ApplicationController < ActionController::Base
    layout 'application'
    protect_from_forgery with: :exception
  end
end
