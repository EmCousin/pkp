# frozen_string_literal: true

class CourseUnavailabilityPeriod < ApplicationRecord
  attribute :conflict_confirmation, :boolean, default: false

  belongs_to :platform
  has_many :course_unavailabilities, dependent: :destroy
  has_many :courses, through: :course_unavailabilities

  validates :starts_on, :ends_on, presence: true
  validates :ends_on, comparison: { greater_than_or_equal_to: :starts_on }, allow_nil: true, if: :starts_on?
  validates :courses, presence: true
  validate :courses_must_belong_to_platform, if: :platform_id?

  def conflicting_discovery_sessions
    return DiscoverySession.none unless platform && starts_on && ends_on

    sessions = platform.discovery_sessions.active.where(course_id: course_ids)
    sessions_on_period(sessions).includes(:course, :subscriptions).order(:starts_at, :id)
  end

  private

  def sessions_on_period(sessions)
    scheduled_sessions = sessions.where(occurs_on: starts_on..ends_on)
    legacy_times = starts_on.in_time_zone..ends_on.in_time_zone.end_of_day
    legacy_sessions = sessions.where(occurs_on: nil, starts_at: legacy_times)

    scheduled_sessions.or(legacy_sessions)
  end

  def courses_must_belong_to_platform
    errors.add(:courses, :wrong_platform) unless courses.all? { |course| course.platform_id == platform_id }
  end
end
