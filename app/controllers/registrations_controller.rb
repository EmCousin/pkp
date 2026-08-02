# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      return render :new, status: :unprocessable_content if resource.errors.any?
    end
  end

  def update
    super do |resource|
      return render :edit, status: :unprocessable_content if resource.errors.any?

      return redirect_to :dashboard, status: :see_other, notice: t('devise.registrations.updated')
    end
  end

  def destroy
    return super if resource.destroyable?

    redirect_to edit_user_registration_path,
                alert: t('devise.registrations.destroy.finalized_event_registration'),
                status: :see_other
  end

  protected

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end

  private

  def update_resource(resource, params)
    super && resource.valid?(:account_setup)
  end
end
