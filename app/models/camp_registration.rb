# frozen_string_literal: true

class CampRegistration < EventRegistration
  validates :subscription_camp, presence: true
  validates :courses, :discovery_session, absence: true

  def self.model_name
    Subscription.model_name
  end

  def completion_open?
    !camp.starts_at.past?
  end

  def description
    @description ||= camp.title
  end

  def notify_confirmation!
    SubscriptionMailer.confirm_camp_subscription(self).deliver_later
  end

  private

  def calculated_fee
    subscription_camp&.price_for(member)
  end

  def registration_event
    subscription_camp
  end
end
