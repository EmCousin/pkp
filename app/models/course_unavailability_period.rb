# frozen_string_literal: true

class CourseUnavailabilityPeriod < ApplicationRecord
  attr_reader :conflicting_discovery_sessions, :conflict_confirmation_token

  belongs_to :platform
  has_many :course_unavailabilities, dependent: :destroy
  has_many :courses, through: :course_unavailabilities

  validates :starts_on, :ends_on, presence: true
  validates :courses, presence: true
  validate :ends_on_cannot_precede_starts_on
  validate :courses_must_belong_to_platform

  def save_with_course_locks(conflict_confirmation_token: nil)
    with_course_locks do
      save_after_conflict_check(conflict_confirmation_token:)
    end
  end

  def destroy_with_course_locks
    with_course_locks { destroy }
  end

  def update_with_course_locks(attributes, conflict_confirmation_token: nil)
    target_course_ids = Array(attributes[:course_ids]).compact_blank.map(&:to_i)
    saved = false

    transaction do
      lock_courses(course_ids | target_course_ids)
      assign_attributes(attributes)
      saved = save_after_conflict_check(conflict_confirmation_token:)
      raise ActiveRecord::Rollback unless saved
    end

    saved
  end

  def conflict_confirmation_required?
    @conflict_confirmation_required
  end

  private

  def save_after_conflict_check(conflict_confirmation_token:)
    @conflicting_discovery_sessions = []
    @conflict_confirmation_required = false
    return false unless valid?

    @conflicting_discovery_sessions = discovery_session_conflicts.to_a
    snapshot = conflict_snapshot
    return false unless conflict_confirmation_matches?(conflict_confirmation_token, snapshot)

    save
  end

  def conflict_confirmation_matches?(token, snapshot)
    return true if confirmation_matches?(token, snapshot)

    @conflict_confirmation_required = true
    @conflict_confirmation_token = conflict_confirmation_verifier.generate(
      { platform_id:, conflicts: snapshot },
      purpose: :course_unavailability_conflicts
    )
    false
  end

  def confirmation_matches?(token, snapshot)
    return snapshot.empty? if token.blank?

    conflict_confirmation_verifier.verified(token, purpose: :course_unavailability_conflicts) == {
      platform_id:,
      conflicts: snapshot
    }
  end

  def conflict_snapshot
    conflicting_discovery_sessions.map do |session|
      {
        session_id: session.id,
        course_id: session.course_id,
        occurrence_date: session.occurrence_date.iso8601,
        confirmed_registration_count: session.subscriptions.count(&:confirmed?)
      }
    end
  end

  def conflict_confirmation_verifier
    Rails.application.message_verifier(:course_unavailability_conflicts)
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
