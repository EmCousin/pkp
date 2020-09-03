# frozen_string_literal: true

module Subscriptions
  module Filterable
    extend ActiveSupport::Concern

    class_methods do
      def filter_by_status(status)
        return all unless status.present?

        where(status: status)
      end
    end
  end
end
