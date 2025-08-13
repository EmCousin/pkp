# frozen_string_literal: true

module Subscriptions
  module Limitable
    extend ActiveSupport::Concern

    included do
      with_options unless: :subscription_camp do
        validates :courses, presence: { message: :must_exist }
        validates :courses_count, numericality: { greater_than: 0, message: :must_exist }
        validates :courses_count, numericality: { less_than_or_equal_to: :max_courses_count, message: :limit_exceeded }
        validate :courses_are_of_the_same_category
        validate :maximum_one_course_per_day
        validate :courses_must_be_available, on: :create
      end
    end

    private

    def max_courses_count
      return 3 unless courses_category # fallback to 3 if no category

      current_pricing = courses_category.current_pricing
      return legacy_max_courses_count unless current_pricing&.prices&.any?

      # For dynamic pricing, only allow as many courses as there are prices
      current_pricing.prices.size
    end

    def legacy_max_courses_count
      return 3 unless courses_category

      # Check if we're in a special time period that has different limits
      if self.class.winter_time?
        legacy_winter_max_courses_count
      elsif self.class.spring_time?
        legacy_spring_max_courses_count
      else
        legacy_default_max_courses_count
      end
    end

    def legacy_winter_max_courses_count
      case courses_category.title
      # when 'Adulte', 'Adolescent (10 - 12 ans)', 'Adolescent (13 - 15 ans)'
      #   2  # Winter pricing supports [205, 275]
      when 'Kidz (6 - 7 ans)', 'Kidz (8 - 9 ans)'
        1 # Winter pricing supports [155]
      else
        2
      end
    end

    def legacy_spring_max_courses_count
      case courses_category.title
      # when 'Adulte', 'Adolescent (10 - 12 ans)', 'Adolescent (13 - 15 ans)'
      #   2  # Spring pricing supports [145, 215]
      when 'Kidz (6 - 7 ans)', 'Kidz (8 - 9 ans)'
        1 # Spring pricing supports [120]
      else
        2
      end
    end

    def legacy_default_max_courses_count
      case courses_category.title
      # when 'Adulte'
      #   3  # Default pricing supports [240, 360, 420]
      when 'Adolescent (10 - 12 ans)', 'Adolescent (13 - 15 ans)'
        2  # Default pricing supports [240, 360]
      when 'Kidz (6 - 7 ans)', 'Kidz (8 - 9 ans)'
        1  # Default pricing supports [210]
      else
        3
      end
    end

    def courses_count
      courses.size
    end

    def courses_are_of_the_same_category
      return if courses.empty? # Skip if no courses

      unique_category = courses.map(&:category).uniq.size == 1

      errors.add(:courses, :unique_category) unless unique_category
    end

    def maximum_one_course_per_day
      return if courses.empty? # Skip if no courses

      weekdays = courses.map(&:weekday)

      errors.add(:courses, :unique_weekday) if weekdays.uniq.size < weekdays.size
    end

    def courses_must_be_available
      return if courses.empty? # Skip if no courses

      errors.add(:courses, :unavailable) if courses.any? { |c| !c.available? }
    end
  end
end
