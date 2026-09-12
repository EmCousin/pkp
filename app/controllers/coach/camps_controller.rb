# frozen_string_literal: true

module Coach
  class CampsController < BaseController
    def index
      @camps = Current.platform.camps.active.upcoming.order(:starts_at)
    end

    def show
      @camp = Current.platform.camps.find(params.expect(:id))
      @subscriptions = @camp.subscriptions
                            .confirmed
                            .includes(member: %i[user avatar_attachment])
                            .joins(:member)
                            .order('members.last_name', 'members.first_name')
    end
  end
end
