# frozen_string_literal: true

module Subscriptions
  module Seasonable
    extend ActiveSupport::Concern

    included do
      after_initialize :set_current_year

      validates :year, presence: true
    end

    class_methods do
      def previous_year
        current_year - 1
      end

      def current_year(datetime = Time.current)
        datetime.month < Course::VACATION_MONTHS.first ? datetime.year - 1 : datetime.year
      end

      def next_year
        current_year + 1
      end
    end

    def season
      "#{year} / #{year + 1}"
    end

    private

    def set_current_year
      self.year ||= self.class.current_year
    end
  end
end
