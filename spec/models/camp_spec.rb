require 'rails_helper'

describe Camp, type: :model do
  it { is_expected.to have_rich_text(:description) }
  it { is_expected.to have_one_attached(:cover_picture) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_presence_of(:starts_at) }
  it { is_expected.to validate_presence_of(:ends_at) }
  it { is_expected.to validate_presence_of(:price) }
  it { is_expected.to validate_presence_of(:external_price) }

  it { is_expected.to validate_numericality_of(:capacity).is_greater_than_or_equal_to(1).only_integer }
  it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }
  it { is_expected.to validate_numericality_of(:external_price).is_greater_than(0) }

  it { is_expected.to have_many(:camps_subscriptions).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:subscriptions).through(:camps_subscriptions) }
  it { is_expected.to have_many(:members).through(:subscriptions) }

  describe 'validations' do
    it 'validates ends_at is after starts_at' do
      camp = build(:camp, starts_at: 1.week.from_now, ends_at: 1.week.ago)
      expect(camp).not_to be_valid
      expect(camp.errors[:ends_at]).to include("doit être plus tard ou le même jour la date de début (#{I18n.l(camp.starts_at, format: :short)})")
    end

    it 'allows same day for starts_at and ends_at' do
      date = 1.week.from_now.to_date
      camp = build(:camp, starts_at: date, ends_at: date)
      expect(camp).to be_valid
    end
  end

  describe 'scopes' do
    let!(:active_camp) { create(:camp, active: true) }
    let!(:inactive_camp) { create(:camp, active: false) }
    let!(:past_camp) { create(:camp, starts_at: 1.week.ago, ends_at: 1.week.ago) }
    let!(:future_camp) { create(:camp, starts_at: 1.week.from_now, ends_at: 1.week.from_now) }

    describe '.active' do
      it 'returns only active camps' do
        expect(described_class.active).to include(active_camp)
        expect(described_class.active).not_to include(inactive_camp)
      end
    end

    describe '.upcoming' do
      it 'returns only upcoming camps' do
        expect(described_class.upcoming).to include(future_camp)
        expect(described_class.upcoming).not_to include(past_camp)
      end
    end

    describe '.available' do
      it 'returns only active and upcoming camps' do
        expect(described_class.available).to include(active_camp, future_camp)
        expect(described_class.available).not_to include(inactive_camp, past_camp)
      end
    end
  end

  describe '#duration_days' do
    it 'calculates correct duration' do
      camp = build(:camp, starts_at: Date.new(2024, 1, 1), ends_at: Date.new(2024, 1, 5))
      expect(camp.duration_days).to eq(5)
    end

    it 'returns 1 for same day' do
      date = Date.new(2024, 1, 1)
      camp = build(:camp, starts_at: date, ends_at: date)
      expect(camp.duration_days).to eq(1)
    end
  end

  describe '#available_slots' do
    let(:camp) { create(:camp, capacity: 10) }

    it 'returns full capacity when no subscriptions' do
      expect(camp.available_slots).to eq(10)
    end

    it 'returns remaining slots after subscriptions' do
      member = create(:member)
      course = create(:course)
      parent_subscription = create(:subscription, status: :confirmed, courses: [course], member:)
      subscription = build(:camp_registration, status: :confirmed, parent_subscription:, member:)
      create(:camps_subscription, camp:, subscription:)
      expect(camp.available_slots).to eq(9)
    end

    it 'reserves capacity for pending subscriptions' do
      member = create(:member)
      course = create(:course)
      parent_subscription = create(:subscription, status: :confirmed, courses: [course], member:)
      subscription = build(:camp_registration, status: :pending, parent_subscription:, member:)
      create(:camps_subscription, camp:, subscription:)
      expect(camp.available_slots).to eq(9)
    end
  end

  describe '#fully_booked?' do
    let(:camp) { create(:camp, capacity: 1) }

    it 'returns false when slots available' do
      expect(camp.fully_booked?).to be_falsey
    end

    it 'returns true when no slots available' do
      member = create(:member)
      course = create(:course)
      parent_subscription = create(:subscription, status: :confirmed, courses: [course], member:)
      subscription = build(:camp_registration, status: :confirmed, parent_subscription:, member:)
      create(:camps_subscription, camp:, subscription:)
      expect(camp.fully_booked?).to be_truthy
    end
  end

  describe '#price_for' do
    let(:camp) { create(:camp, price: 100, external_price: 140, open_to_externals: true) }
    let(:member) { create(:member) }

    it 'returns the external price without an annual subscription' do
      expect(camp.price_for(member)).to eq(140)
    end

    it 'returns the internal price with a confirmed annual subscription' do
      create(:subscription, member:, courses: [create(:course)], status: :confirmed, year: camp.year)

      expect(camp.price_for(member)).to eq(100)
    end
  end

  it 'cannot be destroyed while registrations exist' do
    camp = create(:camp, open_to_externals: true)
    create(
      :camp_registration,
      year: camp.year,
      camps_subscription_attributes: { camp_id: camp.id }
    )

    expect(camp.destroy).to be false
    expect(camp).to be_persisted
  end

  it 'cannot move registrations to another season' do
    boundary = Course.vacation_start(1.year.from_now.year)
    camp = create(:camp, starts_at: boundary - 1.day, ends_at: boundary - 1.day, open_to_externals: true)
    create(
      :camp_registration,
      year: camp.year,
      camps_subscription_attributes: { camp_id: camp.id }
    )

    expect(camp.update(starts_at: boundary, ends_at: boundary)).to be false
    expect(camp.errors.of_kind?(:starts_at, :event_year_locked)).to be true
  end
end
