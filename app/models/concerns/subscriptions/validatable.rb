# frozen_string_literal: true

module Subscriptions
  module Validatable
    extend ActiveSupport::Concern

    included do
      after_initialize :set_current_year

      validates :fee, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
      validates :year, presence: true
      validates :member_id, uniqueness: { scope: :year, message: lambda do |subscription, _data|
        I18n.t(
          'custom_error_messages.subscription.member_id.taken',
          full_name: subscription.member.full_name,
          year: subscription.year
        )
      end }

      validate :at_least_one_course?
      validate :maximum_three_courses?
      validate :courses_are_of_the_same_category
      validate :maximum_one_course_per_day

      with_options if: :category? do
        validate :minimum_age_permited
        validate :maximum_age_permited
      end
    end

    class_methods do
      def current_year
        now = Time.current
        now.month < Course::VACATION_MONTHS.first ? now.year - 1 : now.year
      end
    end

    private

    def at_least_one_course?
      errors.add(:courses, :must_exist) if courses.empty?
    end

    def maximum_three_courses?
      errors.add(:courses, :limit_exceeded) if courses.size > 3
    end

    def courses_are_of_the_same_category
      unique_category = courses.map(&:category).uniq.size == 1

      errors.add(:courses, :unique_category) unless unique_category
    end

    def maximum_one_course_per_day
      weekdays = courses.map(&:weekday)

      errors.add(:courses, :unique_weekday) if weekdays.uniq.size < weekdays.size
    end

    def minimum_age_permited
      errors.add(:member, :too_young) if member_too_young?
    end

    def maximum_age_permited
      errors.add(:member, :too_old) if member_too_old?
    end

    def member_too_old?
      member.age(year) > category.max_age
    end

    def member_too_young?
      member.age(year) < category.min_age
    end

    def set_current_year
      self.year ||= self.class.current_year
    end

    def category?
      category.present?
    end
  end
end
