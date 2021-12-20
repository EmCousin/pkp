# frozen_string_literal: true

module Subscriptions
  module Priceable
    extend ActiveSupport::Concern

    class_methods do
      def spring_time?
        spring_time_range.cover?(Time.current)
      end

      def winter_time?
        winter_time_range.cover?(Time.current)
      end

      def spring_time_range
        Range.new(
          DateTime.new(Subscription.next_year, 4, 1).beginning_of_day,
          DateTime.new(Subscription.next_year, Course::VACATION_MONTHS.first, 1).beginning_of_day
        )
      end

      def winter_time_range
        Range.new(
          DateTime.new(Subscription.current_year, 12, 20).beginning_of_day,
          DateTime.new(Subscription.next_year, Course::VACATION_MONTHS.first, 1).beginning_of_day
        )
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
      return spring_pricing if self.class.spring_time?
      return winter_pricing if self.class.winter_time?

      default_pricing
    end

    def spring_pricing
      case category.title
      when 'Adulte', 'Adolescent (10 - 12 ans)', 'Adolescent (13 - 15 ans)'
        [120, 180]
      when 'Kidz (6 - 7 ans)', 'Kidz (8 - 9 ans)'
        [100]
      end
    end

    def winter_pricing
      case category.title
      when 'Adulte', 'Adolescent (10 - 12 ans)', 'Adolescent (13 - 15 ans)'
        [170, 230]
      when 'Kidz (6 - 7 ans)', 'Kidz (8 - 9 ans)'
        [130]
      end
    end

    def default_pricing
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
