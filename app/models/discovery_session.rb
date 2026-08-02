# frozen_string_literal: true

class DiscoverySession < ApplicationRecord
  include Events::CapacityLimited

  belongs_to :course
  has_many :subscriptions, dependent: :restrict_with_error
  has_many :members, through: :subscriptions

  validates :starts_at, :capacity, :price, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :price, numericality: { greater_than: 0 }
  validate :registration_year_must_match
  validate :occurs_on_matches_course_schedule, on: :create, if: :occurs_on?
  validate :course_date_must_be_unique, if: :course_or_date_changed?

  scope :active, -> { where(active: true) }
  scope :starting_from, lambda { |time|
    where.not(occurs_on: nil).where(occurs_on: time.to_date..)
         .or(where(occurs_on: nil, starts_at: time..))
  }
  scope :upcoming, -> { starting_from(Time.current) }
  scope :recent, -> { starting_from(1.day.ago) }
  scope :available, -> { active.upcoming }

  class << self
    def find_or_create_for_course!(course:, occurs_on:)
      course.with_lock do
        find_for_course_on(course, occurs_on) || create_for_course_on!(course, occurs_on)
      end
    end

    private

    def find_for_course_on(course, occurs_on)
      sessions = course.discovery_sessions
      day = Time.zone.local(occurs_on.year, occurs_on.month, occurs_on.day).all_day
      sessions.find_by(occurs_on:) || sessions.find_by(occurs_on: nil, starts_at: day)
    end

    def create_for_course_on!(course, occurs_on)
      course.discovery_sessions.create!(
        occurs_on:,
        starts_at: Time.zone.local(occurs_on.year, occurs_on.month, occurs_on.day, 12),
        capacity: course.discovery_capacity,
        price: course.discovery_price,
        active: true,
        open: true
      )
    end
  end

  def closed?
    !open_for_registration?
  end

  def occurrence_date
    occurs_on || starts_at.to_date
  end

  def registration_open?
    occurs_on? ? !occurs_on.past? : !starts_at.past?
  end

  def open_for_registration?
    return false unless active? && open? && registration_open?

    occurs_on.nil? || (course.active? && course.discovery_enabled?)
  end

  def year
    Subscription.current_year(occurrence_date)
  end

  private

  def registration_year_must_match
    return unless starts_at && subscriptions.where.not(year: year).exists?

    errors.add(:starts_at, :event_year_locked)
  end

  def occurs_on_matches_course_schedule
    return if course&.discovery_date_available?(occurs_on)

    errors.add(:occurs_on, :unavailable)
  end

  def course_date_must_be_unique
    return unless course && starts_at

    errors.add(:starts_at, :taken) if course_sessions_on_occurrence_date.exists?
  end

  def course_sessions_on_occurrence_date
    sessions = course.discovery_sessions.where.not(id:)
    legacy_sessions = sessions.where(occurs_on: nil, starts_at: occurrence_date.in_time_zone.all_day)
    sessions.where(occurs_on: occurrence_date).or(legacy_sessions)
  end

  def course_or_date_changed?
    new_record? || will_save_change_to_course_id? || will_save_change_to_starts_at? || will_save_change_to_occurs_on?
  end
end
