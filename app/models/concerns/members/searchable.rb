# frozen_string_literal: true

module Members
  module Searchable
    extend ActiveSupport::Concern

    included do
      scope(:for_category, lambda do |category_id|
        joins(subscriptions: { courses: :category })
          .where(subscriptions: { year: Subscription.current_year })
          .where(categories: { id: category_id })
      end)

      scope(:for_subscription_year, lambda do |subscription_year|
        joins(:subscriptions)
          .rewhere(subscriptions: { year: subscription_year })
      end)
    end

    class_methods do
      def search(query)
        return all if query.blank?

        joins(:user).where(
          'LOWER(first_name) LIKE :search
          OR LOWER(last_name) LIKE :search
          OR LOWER(users.email) LIKE :search
          OR users.phone_number LIKE :search',
          search: "%#{query.downcase}%"
        )
      end
    end
  end
end
