# frozen_string_literal: true

module Coach
  class CampsController < BaseController
    def index
      @camps = Current.platform.camps.active.upcoming.order(:starts_at)
    end

    def show
      @camp = Current.platform.camps.find(params.expect(:id))
    end
  end
end
