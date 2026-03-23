# frozen_string_literal: true

require 'rails_helper'

describe CapacitiesCourse, type: :model do
  it { is_expected.to belong_to(:course) }
  it { is_expected.to validate_presence_of(:level) }
  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_numericality_of(:capacity).is_greater_than_or_equal_to(0).only_integer }

  describe 'enums' do
    it 'defines level enum with prefix' do
      expect(described_class.levels.keys).to contain_exactly('white', 'yellow', 'green', 'red')
    end
  end

  describe 'uniqueness validation' do
    let(:course) { create(:course) }

    it 'prevents duplicate levels for the same course' do
      create(:capacities_course, course: course, level: 'white')
      duplicate = build(:capacities_course, course: course, level: 'white')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:level]).to include('has already been taken')
    end

    it 'allows same level for different courses' do
      course1 = create(:course)
      course2 = create(:course)
      create(:capacities_course, course: course1, level: 'white')
      capacity2 = build(:capacities_course, course: course2, level: 'white')

      expect(capacity2).to be_valid
    end
  end
end
