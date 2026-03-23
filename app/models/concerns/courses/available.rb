# frozen_string_literal: true

module Courses
  module Available
    extend ActiveSupport::Concern

    included do
      scope :active, -> { where(active: true) }
    end

    class_methods do
      def available(year = Subscription.current_year)
        return none if year > Subscription.current_year

        active.where(id: with_courses_available(year))
      end

      def with_courses_available(year)
        includes(:subscriptions, :course_capacities).select do |course|
          course.available?(year)
        end
      end
    end

    def available?(year = Subscription.current_year)
      availability(year).positive?
    end

    def availability(year = Subscription.current_year)
      return capacity - active_subscriptions(year).size unless level_capacities?

      total_capacity = course_capacities.sum(:capacity)
      total_capacity - active_subscriptions(year).size
    end

    def available_for_level?(level, year = Subscription.current_year)
      return availability(year).positive? unless level_capacities?

      level_capacity = course_capacities.find_by(level:)&.capacity || 0
      level_subscriptions = active_subscriptions(year).count { |s| s.member.level == level }

      (level_capacity - level_subscriptions).positive?
    end

    def availability_for_level(level, year = Subscription.current_year)
      return availability(year) unless level_capacities?

      level_capacity = course_capacities.find_by(level:)&.capacity || 0
      level_subscriptions = active_subscriptions(year).count { |s| s.member.level == level }

      level_capacity - level_subscriptions
    end

    def level_capacities?
      course_capacities.any?
    end

    private

    def active_subscriptions(year)
      subscriptions.reject do |subscription|
        subscription.archived? || subscription.year != year
      end
    end
  end
end
