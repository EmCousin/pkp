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
    Time.current.month.in?(Course::ALUMNI_MONTHS) && alumni_starting_date.past?
  end

  def alumni_starting_date
    DateTime.new(Subscription.current_year, Course::ALUMNI_MONTHS.first, 4).beginning_of_day
  end

  def full?
    Course.available.empty?
  end
end
