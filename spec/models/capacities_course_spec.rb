# frozen_string_literal: true

require 'rails_helper'

describe CapacitiesCourse, type: :model do
  it { is_expected.to belong_to(:course) }

  it { is_expected.to define_enum_for(:level).with_values(Member.levels).with_prefix }

  it { is_expected.to validate_presence_of(:level) }
  it { is_expected.to validate_uniqueness_of(:level).scoped_to(:course_id) }
  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_numericality_of(:capacity).is_greater_than_or_equal_to(0).only_integer }
end
