# frozen_string_literal: true

module Subscriptions
  module Priceable
    extend ActiveSupport::Concern

    WINTER_PRICING = [130, 190, 220].freeze

    class_methods do
      def winter_time?
        Range.new(
          DateTime.new(Subscription.current_year, 12, 20).beginning_of_day,
          DateTime.new(Subscription.next_year, Course::VACATION_MONTHS.first, 1).beginning_of_day
        ).cover?(Time.current)
      end
    end

    included do
      before_save :set_category_id
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
      self.fee = pricing[courses.size - 1]
    end

    def pricing
      return WINTER_PRICING if self.class.winter_time?

      case category.title
      when 'Adulte'
        [200, 300, 350]
      when 'Adolescent (10 - 12 ans)', 'Adolescent (13 - 15 ans)'
        [200, 300]
      when 'Kidz (6 - 7 ans)', 'Kidz (8 - 9 ans)'
        [175]
      end
    end
  end
end
