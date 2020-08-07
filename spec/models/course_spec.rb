require 'rails_helper'

describe Course, type: :model do
  it { is_expected.to have_many(:courses_subscriptions).dependent(:destroy) }
  it { is_expected.to have_many(:subscriptions).through(:courses_subscriptions) }
  it { is_expected.to have_many(:members).through(:subscriptions) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_presence_of(:category) }
  it { is_expected.to validate_inclusion_of(:category).in_array(described_class::CATEGORIES) }

  it { is_expected.to define_enum_for(:weekday).with_values({ lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7 }) }

  describe 'constants' do
    it 'has a constant CATEGORIES' do
      expect(described_class::CATEGORIES).to eq ['Adulte', 'Adolescent (13 - 15 ans)', 'Adolescent (10 - 12 ans)', 'Kidz (6 - 9 ans)'].freeze
    end
  end
end
