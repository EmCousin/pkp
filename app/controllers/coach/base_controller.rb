# frozen_string_literal: true

module Coach
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_current_user_is_coach

    def index; end

    private

    def ensure_current_user_is_coach
      return if current_user.coach?

      sign_out current_user
      redirect_to after_sign_out_path_for(:user)
    end
  end
end
