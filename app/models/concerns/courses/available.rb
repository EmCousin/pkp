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
        includes(:subscriptions).select do |course|
          course.available?(year)
        end
      end

      def available_for_level(level, year = Subscription.current_year)
        return none if year > Subscription.current_year

        active.where(id: with_courses_available_for_level(level, year))
      end

      def with_courses_available_for_level(level, year)
        includes(:subscriptions, :course_level_capacities).select do |course|
          course.available_for_level?(level, year)
        end
      end
    end

    def available?(year = Subscription.current_year)
      availability(year).positive?
    end

    def availability(year = Subscription.current_year)
      capacity - active_subscriptions(year).size
    end

    def available_for_level?(level, year = Subscription.current_year)
      level_availability(level, year).positive?
    end

    def level_availability(level, year = Subscription.current_year)
      level_capacity = course_level_capacities.find_by(level: level)&.capacity
      return availability(year) if level_capacity.nil? || level_capacity.zero?

      level_capacity - active_subscriptions_for_level(level, year).size
    end

    def level_capacities_configured?
      course_level_capacities.any? { |clc| clc.capacity.positive? }
    end

    def total_level_capacity
      course_level_capacities.sum(:capacity)
    end

    private

    def active_subscriptions(year)
      subscriptions.reject do |subscription|
        subscription.archived? || subscription.year != year
      end
    end

    def active_subscriptions_for_level(level, year)
      active_subscriptions(year).select do |subscription|
        subscription.member.level == level
      end
    end
  end
end
