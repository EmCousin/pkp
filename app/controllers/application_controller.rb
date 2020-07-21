# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include DeviseOverrides

  before_action :redirect_to_profile_completion_page!, unless: -> { devise_controller? || current_user.valid? }

  private

  def redirect_to_profile_completion_page!
    redirect_to edit_user_registration_path, notice: 'Veuillez compléter votre profil pour continuer'
  end
end
