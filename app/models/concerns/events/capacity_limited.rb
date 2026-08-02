# frozen_string_literal: true

module Events
  module CapacityLimited
    extend ActiveSupport::Concern

    def available_slots
      capacity - occupied_slots_count
    end

    def occupied_slots_count
      subscriptions.not_archived.count
    end

    def fully_booked?
      available_slots <= 0
    end
  end
end
