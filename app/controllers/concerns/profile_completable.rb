# frozen_string_literal: true

module ProfileCompletable
  extend ActiveSupport::Concern

  included do
    before_action :redirect_to_profile_completion_page!, if: :should_complete_profile?
  end

  private

  def redirect_to_profile_completion_page!
    redirect_to edit_user_registration_path, notice: t('defaults.complete_your_profile')
  end

  def should_complete_profile?
    return false if devise_controller?
    return false unless user_signed_in?

    !current_user.valid?(:account_setup)
  end
end
