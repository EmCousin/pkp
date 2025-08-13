# frozen_string_literal: true

module Subscriptions
  module LegacyPriceable
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

    private

    def legacy_price_for_courses_count
      pricing[courses.size - 1]
    end

    def pricing
      return spring_pricing if self.class.spring_time?
      return winter_pricing if self.class.winter_time?

      default_pricing
    end

    def spring_pricing
      case category.title
      when 'Adulte', 'Adolescent (10 - 12 ans)', 'Adolescent (13 - 15 ans)'
        [145, 215]
      when 'Kidz (6 - 7 ans)', 'Kidz (8 - 9 ans)'
        [120]
      end
    end

    def winter_pricing
      case category.title
      when 'Adulte', 'Adolescent (10 - 12 ans)', 'Adolescent (13 - 15 ans)'
        [205, 275]
      when 'Kidz (6 - 7 ans)', 'Kidz (8 - 9 ans)'
        [155]
      end
    end

    def default_pricing
      case category.title
      when 'Adulte'
        [240, 360, 420]
      when 'Adolescent (10 - 12 ans)', 'Adolescent (13 - 15 ans)'
        [240, 360]
      when 'Kidz (6 - 7 ans)', 'Kidz (8 - 9 ans)'
        [210]
      end
    end
  end
end
