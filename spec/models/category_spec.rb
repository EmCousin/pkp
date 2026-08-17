require 'rails_helper'

describe Category, type: :model do
  subject do
    build(:category)
  end

  describe 'public constants' do
    it 'has a constant MIN_AGE' do
      expect(described_class::MIN_AGE).to eq(1)
    end

    it 'has a constant MAX_AGE' do
      expect(described_class::MAX_AGE).to eq(100)
    end
  end

  it { is_expected.to have_many(:courses).dependent(:restrict_with_error) }
  it { is_expected.to belong_to(:platform) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_uniqueness_of(:title) }
  it { is_expected.to validate_presence_of(:min_age) }
  it { is_expected.to validate_numericality_of(:min_age).is_greater_than_or_equal_to(described_class::MIN_AGE).is_less_than(subject.max_age).only_integer }
  it { is_expected.to validate_presence_of(:max_age) }
  it { is_expected.to validate_numericality_of(:max_age).is_less_than_or_equal_to((described_class::MAX_AGE)).is_greater_than(subject.min_age).only_integer }

  it 'does not move a category containing courses to another platform' do
    category = create(:category)
    create(:course, category:)

    expect(category.update(platform: create(:platform, name: 'Other platform'))).to be false
    expect(category.errors.of_kind?(:platform, :locked)).to be true
  end
end
