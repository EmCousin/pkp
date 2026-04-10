# frozen_string_literal: true

require 'rails_helper'

describe Assignment, type: :model do
  subject { assignment }

  let(:course) { create :course }
  let(:coach) { create :member, coach: true }
  let(:assignment) { build :assignment, course: course, coach: coach }

  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:coach).class_name('Member') }

  it { is_expected.to validate_presence_of(:coach) }
  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:level) }
  it { is_expected.to validate_presence_of(:year) }

  it { is_expected.to validate_numericality_of(:year).only_integer }

  describe 'uniqueness validation' do
    subject { described_class.create(course: course, coach: coach, level: :white, year: 2024) }

    it { is_expected.to validate_uniqueness_of(:coach_id).scoped_to(%i[course_id level year]) }
  end

  describe '#level enum' do
    it 'defines the correct levels' do
      expect(described_class.levels.keys).to contain_exactly('white', 'yellow', 'green', 'red')
    end
  end
end
