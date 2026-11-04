# frozen_string_literal: true

class CourseUnavailabilityPeriod < ApplicationRecord
  belongs_to :platform
  has_many :course_unavailabilities, dependent: :destroy
  has_many :courses, through: :course_unavailabilities

  validates :starts_on, :ends_on, presence: true
  validates :courses, presence: true
  validate :ends_on_cannot_precede_starts_on
  validate :courses_must_belong_to_platform

  def save_with_course_locks
    with_course_locks { save }
  end

  def destroy_with_course_locks
    with_course_locks { destroy }
  end

  private

  def with_course_locks
    transaction do
      locked_course_ids = course_ids
      locked_course_ids |= course_unavailabilities.persisted.pluck(:course_id) if persisted?
      Course.where(id: locked_course_ids).order(:id).lock.load
      yield
    end
  end

  def ends_on_cannot_precede_starts_on
    return unless starts_on && ends_on && ends_on < starts_on

    errors.add(:ends_on, :before_starts_on)
  end

  def courses_must_belong_to_platform
    return unless platform
    return if courses.all? { |course| course.platform == platform }

    errors.add(:courses, :wrong_platform)
  end
end
