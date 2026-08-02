require 'rails_helper'

describe Course, type: :model do
  describe 'public constants' do
    it 'has a constant VACATION_MONTHS' do
      expect(described_class::VACATION_MONTHS).to eq([7, 8].freeze)
    end

    it 'has a constant VACATION_START_DAY' do
      expect(described_class::VACATION_START_DAY).to eq(12)
    end

    it 'has a constant ALUMNI_MONTHS' do
      expect(described_class::ALUMNI_MONTHS).to eq([8].freeze)
    end
  end

  it { is_expected.to belong_to(:category) }

  it { is_expected.to have_many(:courses_subscriptions).dependent(:destroy) }
  it { is_expected.to have_many(:subscriptions).through(:courses_subscriptions) }
  it { is_expected.to have_many(:members).through(:subscriptions) }
  it { is_expected.to have_many(:discovery_sessions).dependent(:restrict_with_error) }

  it { is_expected.to define_enum_for(:weekday).with_values({ lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7 }) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_numericality_of(:capacity).is_greater_than_or_equal_to(1).only_integer }

  describe 'discovery configuration' do
    it 'requires a price and capacity when enabled' do
      course = build(:course, discovery_enabled: true, discovery_price: nil, discovery_capacity: nil)

      expect(course).not_to be_valid
      expect(course.errors.of_kind?(:discovery_price, :blank)).to be true
      expect(course.errors.of_kind?(:discovery_capacity, :blank)).to be true
    end

    it 'allows an unconfigured course when discovery is disabled' do
      expect(build(:course, discovery_enabled: false)).to be_valid
    end

    it 'finds the next date matching its ISO weekday' do
      course = build(:course, :discoverable, weekday: :dimanche)

      expect(course.next_discovery_date(from: Date.new(2026, 8, 3))).to eq(Date.new(2026, 8, 9))
    end

    it 'includes the final day of the season' do
      course = build(:course, :discoverable, weekday: :samedi)
      date = Date.new(2026, 7, 11)

      expect(course.discovery_date_available?(date, today: date)).to be true
      expect(course.discovery_date_available?(date + 7.days, today: date)).to be false
    end
  end
end
