# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include DeviseOverrides

  before_action :redirect_to_profile_completion_page!, if: :should_complete_profile?

  private

  def redirect_to_profile_completion_page!
    redirect_to edit_user_registration_path, notice: 'Veuillez compléter votre profil pour continuer'
  end

  def should_complete_profile?
    return false if devise_controller?
    return false unless user_signed_in?

    !current_user.valid?(:account_setup)
  end

  def vacation_time?
    Time.current.month.in?(Course::VACATION_MONTHS)
  end
  helper_method :vacation_time?

  def alumni_time?
    Time.current.month.in?(Course::ALUMNI_MONTHS)
  end
  helper_method :alumni_time?

  def full?
    Course.available.empty?
  end
  helper_method :full?
end
