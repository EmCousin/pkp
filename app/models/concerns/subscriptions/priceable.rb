# frozen_string_literal: true

module Subscriptions
  module Priceable
    extend ActiveSupport::Concern

    included do
      include Subscriptions::LegacyPriceable

      before_save :set_category_id, if: -> { courses.any? }
      before_save :set_fee
      validate :event_year_must_match, if: :event?
    end

    def fee_cents
      (fee * 100).to_i
    end

    private

    def set_category_id
      self.category_id ||= courses.first.category_id
    end

    def set_fee
      return if event_fee_locked?

      self.fee = calculated_fee
    end

    def event_fee_locked?
      event? && persisted?
    end

    def calculated_fee
      return subscription_camp&.price_for(member) if camp?
      return discovery_session&.price if discovery?

      dynamic_price_for_courses_count || legacy_price_for_courses_count
    end

    def event_year_must_match
      event = camp? ? subscription_camp : discovery_session
      return unless event && year
      return if year == event.year

      errors.add(:year, :event_mismatch)
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
