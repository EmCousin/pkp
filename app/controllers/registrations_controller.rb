# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      return render :new, status: :unprocessable_entity if resource.errors.any?
    end
  end

  protected

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end

  private

  def update_resource(resource, params)
    super(resource, params) && resource.valid?(:account_setup)
  end
end
