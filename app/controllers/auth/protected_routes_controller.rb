# frozen_string_literal: true

module Auth
  class ProtectedRoutesController < BaseController
    before_action :authenticate_user!

    def show
      head :not_found unless current_user.admin?
    end
  end
end
