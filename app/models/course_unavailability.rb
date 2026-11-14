# frozen_string_literal: true

class CourseUnavailability < ApplicationRecord
  belongs_to :course_unavailability_period
  belongs_to :course

  validates :course_id, uniqueness: { scope: :course_unavailability_period_id }
  validates :course_platform,
            comparison: { equal_to: :course_unavailability_period_platform, message: :wrong_platform },
            if: %i[course_platform course_unavailability_period_platform]

  delegate :platform, to: :course, prefix: true, allow_nil: true, private: true
  delegate :platform, to: :course_unavailability_period, prefix: true, allow_nil: true, private: true
end
