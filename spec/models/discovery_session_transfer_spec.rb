# frozen_string_literal: true

require 'rails_helper'

describe DiscoverySessionTransfer, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.local(2026, 9, 1)) { example.run } }

  let(:course) { create(:course, :discoverable, weekday: :samedi, title: 'Adultes samedi') }
  let(:source_date) { course.next_discovery_date }
  let(:target_date) { source_date + 1.week }
  let(:source_session) { DiscoverySession.find_or_create_for_course!(course:, occurs_on: source_date) }
  let(:subscription) do
    create(:discovery_registration, discovery_session: source_session, paid_at: Time.current)
  end

  subject(:transfer) { described_class.new(subscription:, occurs_on: target_date.iso8601) }

  describe '#occurs_on' do
    it 'parses an ISO 8601 date string' do
      expect(transfer.occurs_on).to eq(target_date)
    end

    it 'accepts a Date directly' do
      expect(described_class.new(subscription:, occurs_on: target_date).occurs_on).to eq(target_date)
    end

    it 'is nil for a malformed date string' do
      expect(described_class.new(subscription:, occurs_on: 'not-a-date').occurs_on).to be_nil
    end
  end

  describe 'validations' do
    it 'is valid for an available date' do
      expect(transfer).to be_valid
    end

    it 'requires a date' do
      transfer.occurs_on = nil

      expect(transfer).not_to be_valid
      expect(transfer.errors.of_kind?(:occurs_on, :blank)).to be true
    end

    it 'rejects a date outside the course schedule' do
      transfer.occurs_on = target_date + 1.day

      expect(transfer).not_to be_valid
      expect(transfer.errors.of_kind?(:occurs_on, :unavailable)).to be true
    end

    it 'rejects a date whose session is already full' do
      full_session = DiscoverySession.find_or_create_for_course!(course:, occurs_on: target_date)
      full_session.update!(capacity: 1)
      create(:discovery_registration, discovery_session: full_session)

      expect(transfer).not_to be_valid
      expect(transfer.errors.of_kind?(:occurs_on, :unavailable)).to be true
    end
  end

  describe '#perform' do
    it 'transfers the registration and returns true' do
      expect(transfer.perform).to be true
      expect(subscription.reload.discovery_session).to eq(DiscoverySession.find_by!(course:, occurs_on: target_date))
    end

    it 'does not transfer and returns false when invalid' do
      transfer.occurs_on = target_date + 1.day

      expect(transfer.perform).to be false
      expect(subscription.reload.discovery_session).to eq(source_session)
    end
  end
end
