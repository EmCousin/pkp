# frozen_string_literal: true

require 'rails_helper'

describe CapacitiesCourse, type: :model do
  it { is_expected.to belong_to(:course) }

  describe 'enums' do
    it 'defines level enum with prefix' do
      expect(subject).to define_enum_for(:level)
        .with_values(white: 'white', yellow: 'yellow', green: 'green', red: 'red')
        .with_prefix
    end
  end

  it { is_expected.to validate_presence_of(:level) }

  describe 'uniqueness validation' do
    subject { create(:capacities_course) }

    it { is_expected.to validate_uniqueness_of(:level).scoped_to(:course_id) }
  end

  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_numericality_of(:capacity).is_greater_than_or_equal_to(0).only_integer }
end
