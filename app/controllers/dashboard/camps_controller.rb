# frozen_string_literal: true

module Dashboard
  class CampsController < DashboardController
    def index
      @camps = available_camps.select { |camp| camp.visible_to?(members) }
    end

    def show
      @camp = available_camps.find_by(id: params[:id])
      @camp = nil unless @camp && (@camp.visible_to?(members) || registered_for?(@camp))
      redirect_to dashboard_camps_path, notice: t('.unavailable') unless @camp
    end

    private

    def available_camps
      Current.platform.camps.visible.upcoming.order(:starts_at, :created_at).includes(:subscriptions)
    end

    def members
      @members ||= Current.user.members.where(platform: Current.platform).includes(:subscriptions).to_a
    end

    def registered_for?(camp)
      Current.user.subscriptions.where(type: CampRegistration.sti_name).joins(:camp).exists?(camps: { id: camp.id })
    end
  end
end
