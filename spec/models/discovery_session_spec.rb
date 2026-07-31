require 'rails_helper'

describe DiscoverySession, type: :model do
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
end
