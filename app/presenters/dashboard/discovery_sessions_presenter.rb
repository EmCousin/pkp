# frozen_string_literal: true

module Dashboard
  class DiscoverySessionsPresenter
    attr_reader :categories, :category, :courses, :course, :discovery_dates, :discovery_sessions

    def initialize(category_id:, course_id:)
      @categories = discoverable_categories
      @category = categories.find_by(id: category_id)
      @courses = discoverable_courses
      @course = courses.find_by(id: course_id)
      @discovery_dates = available_discovery_dates
      @discovery_sessions = legacy_discovery_sessions
    end

    private

    def discoverable_categories
      Category.joins(:courses).merge(Course.discoverable).distinct.order(:title)
    end

    def discoverable_courses
      category ? category.courses.discoverable.order(:weekday, :title) : Course.none
    end

    def available_discovery_dates
      first_date = course&.next_discovery_date
      first_date ? first_date.step(course.discovery_season_end, 7).to_a : []
    end

    def legacy_discovery_sessions
      DiscoverySession.available
                      .where(occurs_on: nil)
                      .includes(:course, :subscriptions)
                      .order(:starts_at)
    end
  end
end
