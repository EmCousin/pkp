# frozen_string_literal: true

module Coach
  class DiscoverySessionsController < BaseController
    before_action :set_discovery_session, only: :show

    def index
      @discovery_sessions = DiscoverySession.active.recent.includes(:course, :subscriptions).order(:starts_at)
    end

    def show
      @attendance_sheet = AttendanceSheet.find_or_create_for_course(@discovery_session.course, @discovery_session.starts_at.to_date)
      @attendance_records = @attendance_sheet.attendance_records.includes(member: :avatar_attachment)
    end

    private

    def set_discovery_session
      @discovery_session = DiscoverySession.active.find(params[:id])
    end
  end
end
