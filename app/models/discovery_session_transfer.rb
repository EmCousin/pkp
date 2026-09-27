# frozen_string_literal: true

class DiscoverySessionTransfer
  include ActiveModel::Model

  attr_accessor :subscription
  attr_reader :occurs_on

  validates :occurs_on, presence: true
  validate :occurs_on_must_be_available, if: -> { occurs_on }

  def occurs_on=(value)
    @occurs_on = value.is_a?(String) ? Date.iso8601(value) : value
  rescue Date::Error
    @occurs_on = nil
  end

  def course
    subscription.discovery_session.course
  end

  def available_dates
    course.available_discovery_dates(excluding: subscription.discovery_session.occurrence_date)
  end

  def perform
    return false unless valid?

    target_session = DiscoverySession.find_or_create_for_course!(course:, occurs_on:)
    return true if subscription.transfer_to(target_session)

    errors.add(:occurs_on, :unavailable)
    false
  rescue ActiveRecord::RecordInvalid
    errors.add(:occurs_on, :unavailable)
    false
  end

  private

  def occurs_on_must_be_available
    errors.add(:occurs_on, :unavailable) unless available_dates.include?(occurs_on)
  end
end
