# frozen_string_literal: true

class CoursesSubscription < ApplicationRecord
  belongs_to :course
  belongs_to :subscription

  validate :course_must_belong_to_subscription_platform

  private

  def course_must_belong_to_subscription_platform
    return unless course && subscription&.persisted?
    return if course.category&.platform == subscription.member.platform

    errors.add(:course, :wrong_platform)
  end
end
