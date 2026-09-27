# frozen_string_literal: true

class DiscoverySessionTransfer
  include ActiveModel::Model

  attr_accessor :subscription
  attr_reader :occurs_on

  delegate :course, to: 'subscription.discovery_session'

  validates :occurs_on, presence: true
  validates :occurs_on, inclusion: {
    in: ->(transfer) { transfer.available_dates },
    message: :unavailable,
    allow_nil: true
  }

  def occurs_on=(value)
    @occurs_on = value.is_a?(String) ? Date.iso8601(value) : value
  rescue Date::Error
    @occurs_on = nil
  end

  def available_dates
    @available_dates ||= course.available_discovery_dates(excluding: subscription.discovery_session.occurrence_date)
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
end
