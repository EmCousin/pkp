# frozen_string_literal: true

class EventRegistration < Subscription
  def event?
    true
  end

  private

  def event_year_must_match
    return unless registration_event && year
    return if year == registration_event.year

    errors.add(:year, :event_mismatch)
  end
end
