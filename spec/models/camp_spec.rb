require 'rails_helper'

RSpec.describe Camp, type: :model do
  it { is_expected.to have_rich_text(:description) }
  it { is_expected.to have_one_attached(:cover_picture) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_presence_of(:starts_at) }
  it { is_expected.to validate_presence_of(:ends_at) }
  it { is_expected.to validate_presence_of(:price) }

  it { is_expected.to validate_numericality_of(:capacity).is_greater_than_or_equal_to(1).only_integer }
  it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }

  it { is_expected.to have_many(:camps_subscriptions).dependent(:destroy) }
  it { is_expected.to have_many(:subscriptions).through(:camps_subscriptions) }
  it { is_expected.to have_many(:members).through(:subscriptions) }

  describe 'validations' do
    it 'validates ends_at is after starts_at' do
      camp = build(:camp, starts_at: 1.week.from_now, ends_at: 1.week.ago)
      expect(camp).not_to be_valid
      expect(camp.errors[:ends_at]).to include('must be greater than or equal to starts_at')
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
        expect(Camp.active).to include(active_camp)
        expect(Camp.active).not_to include(inactive_camp)
      end
    end

    describe '.upcoming' do
      it 'returns only upcoming camps' do
        expect(Camp.upcoming).to include(future_camp)
        expect(Camp.upcoming).not_to include(past_camp)
      end
    end

    describe '.available' do
      it 'returns only active and upcoming camps' do
        expect(Camp.available).to include(active_camp, future_camp)
        expect(Camp.available).not_to include(inactive_camp, past_camp)
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
      subscription = create(:subscription, status: :confirmed)
      create(:camps_subscription, camp: camp, subscription: subscription)
      expect(camp.available_slots).to eq(9)
    end

    it 'does not count pending subscriptions' do
      subscription = create(:subscription, status: :pending)
      create(:camps_subscription, camp: camp, subscription: subscription)
      expect(camp.available_slots).to eq(10)
    end
  end

  describe '#fully_booked?' do
    let(:camp) { create(:camp, capacity: 1) }

    it 'returns false when slots available' do
      expect(camp.fully_booked?).to be_falsey
    end

    it 'returns true when no slots available' do
      subscription = create(:subscription, status: :confirmed)
      create(:camps_subscription, camp: camp, subscription: subscription)
      expect(camp.fully_booked?).to be_truthy
    end
  end
end
