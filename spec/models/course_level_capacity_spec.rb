# frozen_string_literal: true

require 'rails_helper'

describe CourseLevelCapacity, type: :model do
  it { is_expected.to belong_to(:course) }

  it { is_expected.to validate_presence_of(:level) }
  it { is_expected.to validate_inclusion_of(:level).in_array(Member.levels.keys) }
  it { is_expected.to validate_numericality_of(:capacity).is_greater_than_or_equal_to(0).only_integer }
  it { is_expected.to validate_uniqueness_of(:level).scoped_to(:course_id) }

  it { is_expected.to define_enum_for(:level).with_values(Member.levels) }
end
