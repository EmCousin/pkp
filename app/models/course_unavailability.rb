# frozen_string_literal: true

class CourseUnavailability < ApplicationRecord
  belongs_to :course_unavailability_period
  belongs_to :course

  validates :course_id, uniqueness: { scope: :course_unavailability_period_id }
  validate :course_must_belong_to_period_platform

  private

  def course_must_belong_to_period_platform
    return unless course && course_unavailability_period
    return if course.platform == course_unavailability_period.platform

    errors.add(:course, :wrong_platform)
  end
end
