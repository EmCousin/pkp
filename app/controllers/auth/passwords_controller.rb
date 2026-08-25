# frozen_string_literal: true

module Auth
  class PasswordsController < BaseController
    before_action :redirect_authenticated_user, only: %i[new create]
    before_action :set_user_from_token, only: %i[edit update]

    def new
      @user = User.new
    end

    def edit
      @reset_password_token = params[:reset_password_token]
    end

    def create
      enqueue_auth_instructions Auth::SendResetPasswordInstructionsJob, password_request_params[:email]
      redirect_to new_user_session_path, notice: t('.success'), status: :see_other
    end

    def update
      @reset_password_token = password_params[:reset_password_token]

      if @user.reset_password(**password_reset_attributes)
        sign_in(@user)
        redirect_to dashboard_path, notice: t('.success'), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_user_from_token
      token = params[:reset_password_token] || params.dig(:user, :reset_password_token)
      @user = User.from_reset_password_token(token)
      return if @user

      redirect_to new_user_password_path,
                  alert: t('auth.passwords.invalid_token'),
                  status: :see_other
    end

    def password_request_params
      params.expect(user: [:email])
    end

    def password_params
      params.expect(user: %i[reset_password_token password password_confirmation])
    end

    def password_reset_attributes
      password_params.to_h.symbolize_keys.tap do |attributes|
        attributes[:token] = attributes.delete(:reset_password_token)
      end
    end
  end
end
