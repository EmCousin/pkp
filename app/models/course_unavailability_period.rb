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

  def update_with_course_locks(attributes)
    target_course_ids = Array(attributes[:course_ids]).compact_blank.map(&:to_i)
    saved = false

    transaction do
      lock_courses(course_ids | target_course_ids)
      assign_attributes(attributes)
      saved = save
      raise ActiveRecord::Rollback unless saved
    end

    saved
  end

  private

  def with_course_locks
    transaction do
      locked_course_ids = course_ids
      lock_courses(locked_course_ids)
      yield
    end
  end

  def lock_courses(course_ids)
    Course.where(id: course_ids).order(:id).lock.load
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
