# frozen_string_literal: true

class CourseUnavailabilityPeriod < ApplicationRecord
  attr_reader :conflicting_discovery_sessions

  belongs_to :platform
  has_many :course_unavailabilities, dependent: :destroy
  has_many :courses, through: :course_unavailabilities

  validates :starts_on, :ends_on, presence: true
  validates :courses, presence: true
  validate :ends_on_cannot_precede_starts_on
  validate :courses_must_belong_to_platform

  def save_with_course_locks(confirm_conflicts: false, confirmed_conflict_ids: [])
    with_course_locks do
      save_after_conflict_check(confirm_conflicts:, confirmed_conflict_ids:)
    end
  end

  def destroy_with_course_locks
    with_course_locks { destroy }
  end

  def update_with_course_locks(attributes, confirm_conflicts: false, confirmed_conflict_ids: [])
    target_course_ids = Array(attributes[:course_ids]).compact_blank.map(&:to_i)
    saved = false

    transaction do
      lock_courses(course_ids | target_course_ids)
      assign_attributes(attributes)
      saved = save_after_conflict_check(confirm_conflicts:, confirmed_conflict_ids:)
      raise ActiveRecord::Rollback unless saved
    end

    saved
  end

  private

  def save_after_conflict_check(confirm_conflicts:, confirmed_conflict_ids:)
    @conflicting_discovery_sessions = []
    return false unless valid?

    @conflicting_discovery_sessions = discovery_session_conflicts.to_a
    confirmed_ids = Array(confirmed_conflict_ids).map(&:to_i)
    conflicts_need_confirmation = conflicting_discovery_sessions.any? do |session|
      !confirm_conflicts || confirmed_ids.exclude?(session.id)
    end
    return false if conflicts_need_confirmation

    save
  end

  def discovery_session_conflicts
    sessions = platform.discovery_sessions.active.where(course_id: course_ids)
    sessions_on_period(sessions).includes(:course, :subscriptions).order(:starts_at, :id)
  end

  def sessions_on_period(sessions)
    scheduled_sessions = sessions.where(occurs_on: starts_on..ends_on)
    legacy_times = starts_on.in_time_zone..ends_on.in_time_zone.end_of_day
    legacy_sessions = sessions.where(occurs_on: nil, starts_at: legacy_times)

    scheduled_sessions.or(legacy_sessions)
  end

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
