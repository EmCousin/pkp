# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  DEVISE_KEYS = %i[
    first_name
    last_name
    birthdate
    phone_number
    address
    zip_code
    city
    country
    contact_name
    contact_phone_number
    contact_relationship
    agreed_to_publicity_right
    avatar
    email_confirmation
  ].freeze

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: DEVISE_KEYS)
  end
end
