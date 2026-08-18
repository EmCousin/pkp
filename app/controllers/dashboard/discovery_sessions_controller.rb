# frozen_string_literal: true

module Dashboard
  class DiscoverySessionsController < DashboardController
    def index
      @presenter = DiscoverySessionsPresenter.new(platform: Current.platform, category_id: params[:category_id], course_id: params[:course_id])
    end

    def show
      @discovery_session = Current.platform.discovery_sessions.available.find(params[:id])
    end

    # rubocop:disable Metrics/AbcSize
    def create
      course = Current.platform.courses.discoverable.find(params[:course_id])
      occurs_on = Date.iso8601(params[:occurs_on].to_s)
      return invalid_date_redirect(course) unless course.discovery_date_available?(occurs_on)

      discovery_session = DiscoverySession.find_or_create_for_course!(course:, occurs_on:)
      return invalid_date_redirect(course) unless discovery_session.open_for_registration?

      redirect_to [:dashboard, discovery_session], status: :see_other
    rescue Date::Error
      invalid_date_redirect(course)
    end
    # rubocop:enable Metrics/AbcSize

    private

    def invalid_date_redirect(course)
      redirect_to dashboard_discovery_sessions_path(category_id: course.category_id, course_id: course.id),
                  alert: t('.invalid_date')
    end
  end
end
