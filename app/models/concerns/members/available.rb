# frozen_string_literal: true

module Members
  module Available
    extend ActiveSupport::Concern

    class_methods do
      def available(year = Subscription.current_year)
        return none if year > Subscription.current_year

        left_joins(:subscriptions)
          .where(subscriptions: { id: nil })
          .or(
            left_joins(:subscriptions)
              .where.not(subscriptions: { year: year })
          )
      end
    end
  end
end
