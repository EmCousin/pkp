# frozen_string_literal: true

class CampsSubscription < ApplicationRecord
  belongs_to :camp
  belongs_to :subscription

  validates :camp_id, uniqueness: { scope: :subscription_id, message: 'already subscribed to this camp' }
  validate :camp_must_be_available

  private

  def camp_must_be_available
    return unless camp && subscription
    return if subscription.member.can_subscribe?(camp)
    errors.add(:camp, 'is not available for this member')
  end
end
