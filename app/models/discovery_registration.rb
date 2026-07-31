# frozen_string_literal: true

class DiscoveryRegistration < EventRegistration
  belongs_to :discovery_session

  validates :parent_subscription, :subscription_camp, :courses, absence: true
  validate :discovery_session_must_be_available, on: :create

  def self.model_name
    Subscription.model_name
  end

  def completion_open?
    !discovery_session.starts_at.past?
  end

  def description
    @description ||= discovery_session.course.title
  end

  def notify_confirmation!
    SubscriptionMailer.confirm_discovery_subscription(self).deliver_later
  end

  private

  def calculated_fee
    discovery_session&.price
  end

  def registration_event
    discovery_session
  end

  def discovery_session_must_be_available
    return unless discovery_session && member
    return if member.can_subscribe_to_discovery?(discovery_session)

    errors.add(:discovery_session, :unavailable)
  end
end
