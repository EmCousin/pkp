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
    it 'prevents duplicate levels for the same course' do
      # Create a course which auto-creates capacities via the concern
      course = create(:course)
      
      # Try to create another capacity with the same level (white is already created)
      duplicate = build(:capacities_course, course: course, level: 'white', capacity: 10)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:level].first).to match(/dejà|déjà/i)
    end

    it 'allows same level for different courses' do
      # Use explicit titles to avoid potential uniqueness issues
      course1 = create(:course, title: 'Course One')
      course2 = create(:course, title: 'Course Two')

      # course1 already has 'white' from after_create callback
      # course2 should also have 'white' from after_create callback
      # This test verifies both courses can have their own 'white' capacity
      expect(course1.capacities_courses.find_by(level: 'white')).to be_present
      expect(course2.capacities_courses.find_by(level: 'white')).to be_present
      
      # These should be different records
      expect(course1.capacities_courses.find_by(level: 'white').id).not_to eq(
        course2.capacities_courses.find_by(level: 'white').id
      )
    end
  end
end
