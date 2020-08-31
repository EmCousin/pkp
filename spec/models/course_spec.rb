require 'rails_helper'

describe Course, type: :model do
  describe 'public constants' do
    it 'has a constant VACATION_MONTHS' do
      expect(described_class::VACATION_MONTHS).to eq([7, 8].freeze)
    end

    it 'has a constant ALUMNI_MONTHS' do
      expect(described_class::ALUMNI_MONTHS).to eq([8].freeze)
    end
  end

  it { is_expected.to belong_to(:category) }

  it { is_expected.to have_many(:courses_subscriptions).dependent(:destroy) }
  it { is_expected.to have_many(:subscriptions).through(:courses_subscriptions) }
  it { is_expected.to have_many(:members).through(:subscriptions) }

  it { is_expected.to define_enum_for(:weekday).with_values({ lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7 }) }
end
