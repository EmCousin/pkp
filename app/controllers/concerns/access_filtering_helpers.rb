# frozen_string_literal: true

module AccessFilteringHelpers
  extend ActiveSupport::Concern

  included do
    helper_method :vacation_time?
    helper_method :alumni_time?
    helper_method :full?
  end

  private

  def vacation_time?
    Time.current.month.in?(Course::VACATION_MONTHS)
  end

  def alumni_time?
    Time.current.month.in?(Course::ALUMNI_MONTHS)
  end

  def full?
    Course.available.empty?
  end
end
