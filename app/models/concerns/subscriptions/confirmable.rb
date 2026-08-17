# frozen_string_literal: true

module Subscriptions
  module Confirmable
    extend ActiveSupport::Concern

    included do
      before_destroy :prevent_destroying_finalized_event_registration, prepend: true, unless: :cancellable?
      around_destroy :with_lock_preserving_destroyed_by_association, prepend: true
    end

    def cancellable?
      return false if billing_invoice
      return false if event? && (paid? || confirmed?)
      return false if medical_certificate_source_in_use?

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

    def with_lock_preserving_destroyed_by_association
      association = destroyed_by_association
      with_lock do
        self.destroyed_by_association = association
        yield
      end
    end

    def prevent_destroying_finalized_event_registration
      error = medical_certificate_source_in_use? ? :medical_certificate_in_use : :finalized_event_registration
      errors.add(:base, error)
      throw :abort
    end
  end
end
