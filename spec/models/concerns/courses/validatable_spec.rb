require 'rails_helper'

describe Courses::Validatable, type: :model do
  subject { course }

  let(:course) { build :course }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_numericality_of(:capacity).is_greater_than_or_equal_to(1).only_integer }
end
