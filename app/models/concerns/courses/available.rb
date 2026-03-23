# frozen_string_literal: true

module Courses
  module Available
    extend ActiveSupport::Concern

    included do
      scope :active, -> { where(active: true) }

      after_create :initialize_capacities_courses
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
      capacities_courses.sum(:capacity) - active_subscriptions(year).count
    end

    def availability_for_level(level, year = Subscription.current_year)
      return availability(year) if capacities_courses.empty?

      level_capacity = capacities_courses.find_by(level:)&.capacity || 0
      return availability(year) if level_capacity.zero?

      level_subscriptions = count_active_subscriptions_for_level(level, year)
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

    def count_active_subscriptions_for_level(level, year)
      # Preload members to avoid N+1 query
      subscriptions.includes(:member).count do |subscription|
        !subscription.archived? &&
          subscription.year == year &&
          subscription.member&.level == level
      end
    end

    def initialize_capacities_courses
      Member.levels.each_key do |level|
        capacities_courses.create!(level: level, capacity: 0)
      end
    end
  end
end
