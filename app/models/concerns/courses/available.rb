# frozen_string_literal: true

module Courses
  module Available
    extend ActiveSupport::Concern

    included do
      include Manageable

      scope :active, -> { where(active: true) }
    end

    class_methods do
      def available(year = Subscription.current_year)
        return none if year > Subscription.current_year

        manageable(year).active.where(id: with_courses_available(year))
      end

      def with_courses_available(year)
        includes(:subscriptions).select do |course|
          course.available?(year)
        end
      end
    end

    def available?(year = Subscription.current_year)
      availability(year).positive?
    end

    def availability(year = Subscription.current_year)
      capacity - subscriptions.count do |subscription|
        !subscription.archived? && subscription.year == year
      end
    end
  end
end
