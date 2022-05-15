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
    end

    class_methods do
      def search(query)
        return all unless query.present?

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
