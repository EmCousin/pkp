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

  scope :active, -> { where(active: true) }
  scope :upcoming, -> { where(starts_at: Time.current..) }
  scope :recent, -> { where(starts_at: 1.day.ago..) }
  scope :available, -> { active.upcoming }

  def closed?
    !open?
  end

  def year
    Subscription.current_year(starts_at)
  end

  private

  def registration_year_must_match
    return unless starts_at && subscriptions.where.not(year: year).exists?

    errors.add(:starts_at, :event_year_locked)
  end
end
