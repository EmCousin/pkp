# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include DeviseOverrides
  include ProfileCompletable
  include AccessFilteringHelpers

  default_form_builder ::FormBuilder
end
