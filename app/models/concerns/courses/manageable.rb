# frozen_string_literal: true

module Courses
  module Manageable
    extend ActiveSupport::Concern

    included do
      scope :empty, -> { left_outer_joins(:subscriptions).where(subscriptions: { id: nil }) }
    end

    class_methods do
      def manageable(year = Subscription.current_year)
        with_subscriptions(year).or(empty).distinct
      end

      def with_subscriptions(year = Subscription.current_year)
        left_outer_joins(:subscriptions).where(subscriptions: { year: year })
      end
    end
  end
end
