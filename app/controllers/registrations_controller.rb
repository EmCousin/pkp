# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  protected

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end

  private

  def update_resource(resource, params)
    super(resource, params) && resource.valid?(:account_setup)
  end
end
