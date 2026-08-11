# frozen_string_literal: true

module Subscriptions
  module ProtectsFinalizedRegistrations
    extend ActiveSupport::Concern

    included do
      before_destroy :prevent_destroying_finalized_event_registrations, prepend: true
      around_destroy :with_lock, prepend: true
    end

    def destroyable?
      subscriptions.destruction_protected.empty?
    end

    private

    def prevent_destroying_finalized_event_registrations
      return if destroyable?

      errors.add(:base, :finalized_event_registration)
      throw :abort
    end
  end
end
