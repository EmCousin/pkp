require 'rails_helper'

describe DiscoverySession, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  it { is_expected.to belong_to(:course) }
  it { is_expected.to have_many(:subscriptions).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:members).through(:subscriptions) }

  it { is_expected.to validate_presence_of(:starts_at) }
  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_presence_of(:price) }
  it { is_expected.to validate_numericality_of(:capacity).is_greater_than_or_equal_to(1).only_integer }
  it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }

  describe 'capacity' do
    let(:discovery_session) { create(:discovery_session, capacity: 1) }

    it 'is shared by pending and confirmed registrations' do
      create(:discovery_registration, discovery_session:, member: create(:member))

      expect(discovery_session).to be_fully_booked
      expect(discovery_session.available_slots).to eq(0)
    end

    it 'is released when a registration is archived' do
      create(:discovery_registration, discovery_session:, member: create(:member), status: :archived)

      expect(discovery_session.available_slots).to eq(1)
    end
  end

  it 'cannot be destroyed while registrations exist' do
    discovery_session = create(:discovery_session)
    create(:discovery_registration, discovery_session:)

    expect(discovery_session.destroy).to be false
    expect(discovery_session).to be_persisted
  end

  it 'cannot move registrations to another season' do
    boundary = Course.vacation_start(1.year.from_now.year)
    discovery_session = create(:discovery_session, starts_at: boundary - 1.day)
    create(:discovery_registration, discovery_session:)

    expect(discovery_session.update(starts_at: boundary)).to be false
    expect(discovery_session.errors.of_kind?(:starts_at, :event_year_locked)).to be true
  end

  it 'cannot move registrations to another course' do
    discovery_session = create(:discovery_session)
    create(:discovery_registration, discovery_session:)
    other_platform = create(:platform, name: 'Other platform')
    other_category = create(:category, platform: other_platform, title: 'Other category')
    other_course = create(:course, category: other_category)

    expect(discovery_session.update(course: other_course)).to be false
    expect(discovery_session.errors.of_kind?(:course, :locked)).to be true
  end

  describe '.find_or_create_for_course!' do
    let(:course) { create(:course, :discoverable, weekday: :samedi, discovery_capacity: 8, discovery_price: 30) }
    let(:occurs_on) { course.next_discovery_date }

    it 'creates an active occurrence from the course configuration' do
      discovery_session = described_class.find_or_create_for_course!(course:, occurs_on:)

      expect(discovery_session).to have_attributes(occurs_on:, capacity: 8, price: 30, active: true, open: true)
    end

    it 'reuses the same automatic occurrence' do
      first = described_class.find_or_create_for_course!(course:, occurs_on:)

      expect(described_class.find_or_create_for_course!(course:, occurs_on:)).to eq(first)
    end

    it 'reuses a legacy session on the selected date without changing it' do
      starts_at = Time.zone.local(occurs_on.year, occurs_on.month, occurs_on.day, 18)
      legacy = create(:discovery_session, course:, starts_at:, capacity: 4, price: 19)

      expect(described_class.find_or_create_for_course!(course:, occurs_on:)).to eq(legacy)
      expect(legacy.reload).to have_attributes(occurs_on: nil, capacity: 4, price: 19)
    end

    it 'rejects a second manual session on an automatic occurrence date' do
      described_class.find_or_create_for_course!(course:, occurs_on:)
      duplicate = build(:discovery_session, course:,
                                            starts_at: Time.zone.local(occurs_on.year, occurs_on.month, occurs_on.day, 18))

      expect(duplicate).not_to be_valid
      expect(duplicate.errors.of_kind?(:starts_at, :taken)).to be true
    end

    it 'rejects moving a legacy session onto an occupied date' do
      described_class.find_or_create_for_course!(course:, occurs_on:)
      legacy = create(:discovery_session, course:, starts_at: occurs_on.tomorrow.in_time_zone)

      expect(legacy.update(starts_at: occurs_on.in_time_zone)).to be false
      expect(legacy.errors.of_kind?(:starts_at, :taken)).to be true
    end
  end

  it 'keeps an automatic occurrence available throughout its date' do
    travel_to Time.zone.local(2026, 8, 8, 18) do
      course = create(:course, :discoverable, weekday: :samedi)
      discovery_session = described_class.find_or_create_for_course!(course:, occurs_on: Date.current)

      expect(discovery_session).to be_in(described_class.available)
    end
  end
end
