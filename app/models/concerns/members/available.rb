# frozen_string_literal: true

module Members
  module Available
    extend ActiveSupport::Concern

    class_methods do
      def unavailable(year = Subscription.current_year)
        joins(:subscriptions).merge(
          AnnualSubscription.where(year:, parent_subscription_id: nil)
        )
      end

      def available(year = Subscription.current_year)
        return none if year > Subscription.current_year

        active.where.not(id: unavailable(year))
      end
    end
  end
end
