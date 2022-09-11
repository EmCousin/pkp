# frozen_string_literal: true

module Members
  module Available
    extend ActiveSupport::Concern

    class_methods do
      def unavailable(year = Subscription.current_year)
        joins(:subscriptions).where(subscriptions: { year: year })
      end

      def available(year = Subscription.current_year)
        return none if year > Subscription.current_year

        where.not(id: unavailable(year))
      end
    end
  end
end
