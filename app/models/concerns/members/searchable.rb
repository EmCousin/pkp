# frozen_string_literal: true

module Members
  module Searchable
    extend ActiveSupport::Concern

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
