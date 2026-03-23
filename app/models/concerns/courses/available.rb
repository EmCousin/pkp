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
        includes(:subscriptions, :capacities_courses, subscriptions: :member).select do |course|
          course.available?(year)
        end
      end
    end

    def available?(year = Subscription.current_year)
      availability(year).positive?
    end

    def availability(year = Subscription.current_year)
      capacities_courses.sum(:capacity) - active_subscriptions(year).size
    end

    def availability_for_level(level, year = Subscription.current_year)
      return availability(year) if capacities_courses.empty?

      level_capacity = capacities_courses.find_by(level:)&.capacity || 0
      return availability(year) if level_capacity.zero?

      level_subscriptions = active_subscriptions(year).count { |s| s.member&.level == level }
      level_capacity - level_subscriptions
    end

    def availabilities(year = Subscription.current_year)
      return {} if capacities_courses.empty?

      capacities_courses.to_h do |capacity|
        [capacity.level.to_sym, availability_for_level(capacity.level, year)]
      end
    end

    private

    def active_subscriptions(year)
      subscriptions.reject do |subscription|
        subscription.archived? || subscription.year != year
      end
    end
  end
end
