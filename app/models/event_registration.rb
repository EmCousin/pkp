# frozen_string_literal: true

class EventRegistration < Subscription
  validate :event_must_belong_to_member_platform

  def event?
    true
  end

  private

  def event_year_must_match
    return unless registration_event && year
    return if year == registration_event.year

    errors.add(:year, :event_mismatch)
  end

  def event_must_belong_to_member_platform
    return unless registration_event && member
    return if registration_event.platform == member.platform

    errors.add(:member, :wrong_platform)
  end
end
