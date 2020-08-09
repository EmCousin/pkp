require 'rails_helper'

describe Courses::Validatable, type: :model do
  subject { course }

  let(:course) { build :course }

  describe 'constants' do
    it 'has a constant CATEGORIES' do
      expect(described_class::CATEGORIES).to eq([
        'Adulte',
        'Adolescent (13 - 15 ans)',
        'Adolescent (10 - 12 ans)',
        'Kidz (6 - 9 ans)'
      ].freeze)
    end
  end

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_presence_of(:category) }
  it { is_expected.to validate_inclusion_of(:category).in_array(described_class::CATEGORIES) }
end
