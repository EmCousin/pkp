# frozen_string_literal: true

module Dashboard
  class DiscoverySessionsController < DashboardController
    def index
      set_category_selection
      set_course_selection
      @discovery_sessions = DiscoverySession.available.where(occurs_on: nil).includes(:course, :subscriptions).order(:starts_at)
    end

    def show
      @discovery_session = DiscoverySession.available.find(params[:id])
    end

    def create
      course = Course.discoverable.find(params[:course_id])
      occurs_on = Date.iso8601(params[:occurs_on].to_s)
      return invalid_date_redirect(course) unless course.discovery_date_available?(occurs_on)

      discovery_session = DiscoverySession.find_or_create_for_course!(course:, occurs_on:)
      return invalid_date_redirect(course) unless discovery_session.open_for_registration?

      redirect_to [:dashboard, discovery_session], status: :see_other
    rescue Date::Error
      invalid_date_redirect(course)
    end

    private

    def set_category_selection
      @categories = Category.joins(:courses).merge(Course.discoverable).distinct.order(:title)
      @category = @categories.find_by(id: params[:category_id])
    end

    def set_course_selection
      @courses = @category ? @category.courses.discoverable.order(:weekday, :title) : Course.none
      @course = @courses.find_by(id: params[:course_id])
    end

    def invalid_date_redirect(course)
      redirect_to dashboard_discovery_sessions_path(category_id: course.category_id, course_id: course.id),
                  alert: t('.invalid_date')
    end
  end
end
