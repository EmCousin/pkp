# frozen_string_literal: true

class CampsSubscription < ApplicationRecord
  belongs_to :camp
  belongs_to :subscription

  validates :camp_id, uniqueness: { scope: :subscription_id, message: :already_subscribed_to_this_camp }
  validate :camp_must_be_available
  validate :camp_must_belong_to_subscription_platform

  private

  def camp_must_be_available
    return unless camp && subscription
    return if subscription.member.can_subscribe?(camp)

    errors.add(:camp, 'is not available for this member')
  end

  def camp_must_belong_to_subscription_platform
    return unless camp && subscription
    return if camp.platform == subscription.platform

    errors.add(:camp, :wrong_platform)
  end
end
