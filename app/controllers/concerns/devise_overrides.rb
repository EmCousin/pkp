# frozen_string_literal: true

module DeviseOverrides
  extend ActiveSupport::Concern

  included do
    before_action :configure_permitted_parameters, if: :devise_controller?
  end

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

  def signed_in_root_path(_resource_or_scope)
    dashboard_index_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
