# frozen_string_literal: true

module Auth
  class UnlocksController < BaseController
    before_action :redirect_authenticated_user, only: %i[new create]

    def show
      if User.unlock_by_token(params[:unlock_token])
        redirect_to new_user_session_path, notice: t('.success'), status: :see_other
      else
        redirect_to new_user_unlock_path, alert: t('.invalid'), status: :see_other
      end
    end

    def new
      @user = User.new
    end

    def create
      enqueue_auth_instructions Auth::SendUnlockInstructionsJob, unlock_params[:email]
      redirect_to new_user_session_path, notice: t('.success'), status: :see_other
    end

    private

    def unlock_params
      params.expect(user: [:email])
    end
  end
end
