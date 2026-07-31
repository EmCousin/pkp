# frozen_string_literal: true

module Subscriptions
  module Confirmable
    extend ActiveSupport::Concern

    included do
      before_destroy :prevent_destroying_finalized_event_registration
    end

    def cancellable?
      return false if event? && (paid? || confirmed?)

      !child_subscriptions.finalized_events.exists?
    end

    def confirm!
      confirmed!
      notify_confirmation!
    end

    def notify_confirmation!
      if discovery?
        SubscriptionMailer.confirm_discovery_subscription(self).deliver_later
      elsif camp?
        SubscriptionMailer.confirm_camp_subscription(self).deliver_later
      else
        SubscriptionMailer.confirm_subscription(self).deliver_later
      end
    end

    private

    def prevent_destroying_finalized_event_registration
      return if cancellable?

      errors.add(:base, :finalized_event_registration)
      throw :abort
    end
  end
end
