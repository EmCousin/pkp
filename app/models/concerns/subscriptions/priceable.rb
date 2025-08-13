# frozen_string_literal: true

module Subscriptions
  module Priceable
    extend ActiveSupport::Concern

    included do
      include Subscriptions::LegacyPriceable

      before_save :set_category_id, if: -> { courses.any? }
      before_save :set_fee
    end

    def fee_cents
      (fee * 100).to_i
    end

    private

    def set_category_id
      self.category_id ||= courses.first.category_id
    end

    def set_fee
      self.fee = if parent_subscription.present? && subscription_camp.present?
                   subscription_camp.price
                 else
                   dynamic_price_for_courses_count || legacy_price_for_courses_count
                 end
    end

    def dynamic_price_for_courses_count
      return unless courses_category

      current = courses_category.current_pricing
      return unless current

      # Only allow courses up to the number of prices available
      index = courses.size - 1
      return unless current.prices[index]

      BigDecimal(current.prices[index].to_s)
    end
  end
end
