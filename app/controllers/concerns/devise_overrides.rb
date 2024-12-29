# frozen_string_literal: true

module DeviseOverrides
  extend ActiveSupport::Concern

  included do
    before_action :configure_permitted_parameters, if: :devise_controller?
  end

  DEVISE_SIGN_UP_KEYS = %i[
    email_confirmation
    terms_of_service
  ].freeze

  DEVISE_ACCOUNT_UPDATE_KEYS = (DEVISE_SIGN_UP_KEYS + %i[
    first_name
    last_name
    phone_number
    address
    zip_code
    city
    country
  ] + [{
    contacts_attributes: %i[id email _destroy]
  }]).freeze

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: DEVISE_SIGN_UP_KEYS)
    devise_parameter_sanitizer.permit(:account_update, keys: DEVISE_ACCOUNT_UPDATE_KEYS)
  end

  def signed_in_root_path(_resource_or_scope)
    :dashboard
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
