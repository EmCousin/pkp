# frozen_string_literal: true

require 'rails_helper'

describe SubscriptionMailer, type: :mailer do
  it 'renders the formatted discovery session date' do
    discovery_session = create(:discovery_session, starts_at: Time.zone.local(2026, 9, 12, 14))
    subscription = create(:discovery_registration, discovery_session:)

    mail = described_class.confirm_discovery_subscription(subscription)

    expect(mail.body.encoded).to include(discovery_session.discovery_session_date)
  end
end
