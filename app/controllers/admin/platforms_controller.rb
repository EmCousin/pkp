# frozen_string_literal: true

module Admin
  class PlatformsController < BaseController
    skip_before_action :ensure_current_user_is_admin!
    before_action :ensure_current_user_can_manage_platform!
    before_action :set_platform

    def edit; end

    def update
      if @platform.update(platform_params)
        redirect_to edit_admin_platform_path, notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def ensure_current_user_can_manage_platform!
      return if current_user.admin? || current_user.coach?

      sign_out current_user
      redirect_to after_sign_out_path_for(:user)
    end

    def set_platform
      @platform = Current.platform
    end

    def platform_params
      params.expect(platform: [:medical_certificate_validity_seasons])
    end
  end
end
