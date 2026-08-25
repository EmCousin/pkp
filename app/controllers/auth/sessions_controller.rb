# frozen_string_literal: true

module Auth
  class SessionsController < BaseController
    before_action :redirect_authenticated_user, only: %i[new create]

    def new
      @user = User.new
    end

    def create
      @user = User.new(email: session_params[:email])
      user = User.authenticate_for_session(email: session_params[:email], password: session_params[:password])

      user ? complete_sign_in(user) : render_invalid_credentials
    end

    def destroy
      sign_out
      redirect_to new_user_session_path, notice: t('.success'), status: :see_other
    end

    private

    def session_params
      params.expect(user: %i[email password remember_me])
    end

    def complete_sign_in(user)
      destination = after_authentication_path
      sign_in(user, remember_me: session_params[:remember_me] == '1')
      redirect_to destination, notice: t('.success'), status: :see_other
    end

    def render_invalid_credentials
      flash.now[:alert] = t('auth.failure.invalid')
      render :new, status: :unprocessable_content
    end
  end
end
