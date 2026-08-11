# frozen_string_literal: true

module Subscriptions
  module Confirmable
    extend ActiveSupport::Concern

    included do
      before_destroy :prevent_destroying_finalized_event_registration, prepend: true, unless: :cancellable?
      around_destroy :with_lock, prepend: true
    end

    def cancellable?
      return false if billing_invoice
      return false if event? && (paid? || confirmed?)

      child_subscriptions.destruction_protected.empty?
    end

    def confirm!
      confirmed!
      notify_confirmation!
    end

    def notify_confirmation!
      SubscriptionMailer.confirm_subscription(self).deliver_later
    end

    private

    def prevent_destroying_finalized_event_registration
      errors.add(:base, :finalized_event_registration)
      throw :abort
    end
  end
end
