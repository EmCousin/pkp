# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_current_user_is_admin!
    before_action :set_pricing_warning

    def index; end

    private

    def set_pricing_warning
      @pricing_year = Date.current.year + 1
      @missing_pricing_categories_count = Category.where.not(
        id: Pricing.covering_year(@pricing_year).select(:category_id)
      ).count
    end

    def ensure_current_user_is_admin!
      return if current_user.admin?

      sign_out current_user
      redirect_to after_sign_out_path_for(:user)
    end
  end
end
